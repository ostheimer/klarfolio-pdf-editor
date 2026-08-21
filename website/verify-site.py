#!/usr/bin/env python3
"""Dependency-free static checks for the Klarfolio product website."""

from html.parser import HTMLParser
from pathlib import Path
import re
import sys


SITE_DIRECTORY = Path(__file__).resolve().parent
HTML_FILES = ("index.html", "privacy.html", "support.html")
EXTERNAL_REFERENCE = re.compile(r"^(?:#|https?:|mailto:|tel:|data:)")
TRANSLATION_KEY = re.compile(r'^\s*(?:"([^"]+)"|([A-Za-z][\w-]*)):\s*"', re.MULTILINE)


class SiteParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.references = []
        self.translation_keys = []
        self.meta = {}
        self.download_links = []

    def handle_starttag(self, tag, attrs):
        attributes = dict(attrs)
        for name in ("src", "href"):
            if attributes.get(name):
                self.references.append(attributes[name])
        for name in ("data-i18n", "data-i18n-aria", "data-i18n-alt"):
            if attributes.get(name):
                self.translation_keys.append(attributes[name])
        if tag == "a" and "data-download" in attributes:
            self.download_links.append(attributes)
        if tag == "meta" and attributes.get("name"):
            self.meta[attributes["name"]] = attributes.get("content", "")


def fail(message):
    print(f"Website validation failed: {message}", file=sys.stderr)
    sys.exit(1)


def translation_keys(source, language):
    match = re.search(rf"\n  {language}: \{{(.*?)\n  \}},", source, re.DOTALL)
    if not match:
        fail(f"translation dictionary for {language} is missing")
    return {quoted or bare for quoted, bare in TRANSLATION_KEY.findall(match.group(1))}


def main():
    script = (SITE_DIRECTORY / "site.js").read_text(encoding="utf-8")
    if "../dist/" in script:
        fail("site.js must not point to a local dist directory")

    privacy_source = (SITE_DIRECTORY / "privacy.html").read_text(encoding="utf-8")
    if "localStorage.setItem" in script:
        if "browser's local storage" not in privacy_source or "lokalen Browserspeicher" not in script:
            fail("privacy information must disclose persisted browser language preferences")

    dictionaries = {language: translation_keys(script, language) for language in ("en", "de")}
    parsed_files = {}

    for name in HTML_FILES:
        path = SITE_DIRECTORY / name
        if not path.exists():
            fail(f"{name} is missing")
        source = path.read_text(encoding="utf-8")
        if "../dist/" in source:
            fail(f"{name} must not point to a local dist directory")

        parser = SiteParser()
        parser.feed(source)
        parsed_files[name] = parser

        for reference in parser.references:
            if EXTERNAL_REFERENCE.match(reference):
                continue
            local_path = reference.split("#", 1)[0].split("?", 1)[0]
            if not local_path or not (SITE_DIRECTORY / local_path).exists():
                fail(f"{name} references a missing local file: {reference}")

        for key in parser.translation_keys:
            for language, dictionary in dictionaries.items():
                if key not in dictionary:
                    fail(f"{name}: {language} is missing translation key {key}")

    homepage = parsed_files["index.html"]
    if homepage.meta.get("klarfolio-download-url") != "":
        fail("homepage must default to a disabled download state")

    references = set(homepage.references)
    if "privacy.html" not in references:
        fail("homepage must link to privacy information")
    if "support.html" not in references:
        fail("homepage must link to the local support page")

    if len(homepage.download_links) != 3:
        fail("homepage must contain all three download controls")
    for link in homepage.download_links:
        if link.get("aria-disabled") != "true" or "is-disabled" not in link.get("class", ""):
            fail("download controls must visibly default to the disabled coming-soon state")
        if "href" in link:
            fail("download controls must not have a release link before a release is configured")

    for name in HTML_FILES:
        source = (SITE_DIRECTORY / name).read_text(encoding="utf-8")
        if 'rel="canonical" data-site-canonical' not in source:
            fail(f"{name} is missing its centrally configured canonical URL hook")

    print("Website validation passed.")


if __name__ == "__main__":
    main()

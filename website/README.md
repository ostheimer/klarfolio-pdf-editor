# Klarfolio PDF Editor Website

This folder contains the static product website for Klarfolio PDF Editor.

## Files

- `index.html`: semantic single-page website
- `privacy.html`: privacy information page for the product and static website
- `support.html`: local support hub with links to guides and the public issue tracker
- `styles.css`: responsive visual system
- `site.js`: English/German localization, mobile navigation, future locale registry, and download-state handling
- `verify-site.py`: dependency-free static validation for local links, translations, and release safeguards
- `assets/`: generated product concept and product mockup images

## Localization

English is the default language. German is available through the language switch. Additional languages can be added in `site.js` by extending the `translations` object and enabling a matching language control.

Current planned locale slots: French, Spanish, Italian, Portuguese, Japanese, Korean, Chinese, Arabic, and Hindi.

## Download configuration

The website ships deliberately without a download target. Until a signed release is hosted, every download call-to-action is a clearly labelled, non-interactive **coming soon** state; there are no links to a local `dist/` app bundle.

When the final HTTPS download URL exists, set the `content` value of the `klarfolio-download-url` meta tag in `index.html`, for example:

```html
<meta name="klarfolio-download-url" content="https://downloads.example.com/Klarfolio-PDF-Editor-0.1.0.dmg">
```

Only HTTPS URLs enable the download controls. This prevents accidental publication of local paths or insecure download links.

The later primary domain is configured once at the top of `site.js` through `configuredSiteUrl`. Leave it empty for local and pre-domain use. After setting an HTTPS primary domain, the site adds the matching canonical URL for each page; internal product, support, and privacy navigation remains relative and works before then.

## Support and privacy

- Support and privacy links are local pages (`support.html` and `privacy.html`) so they work before a primary domain exists. The support page links onwards to the public GitHub issue tracker and warns users not to publish documents or other sensitive data there.
- `privacy.html` describes the local-first app behavior and the static website behavior in English and German.
- Before a public-domain launch, add the final website operator, hosting provider, and direct privacy contact to `privacy.html`. These legal publication details are intentionally not invented while no final domain or operator contact is available.

## Validate and open locally

Run the static validation after edits:

```bash
python3 verify-site.py
osascript -l JavaScript -e 'const app = Application.currentApplication(); app.includeStandardAdditions = true; new Function(app.read(Path("site.js")));'
```

Open `index.html` in a browser. No build step or local server is required.

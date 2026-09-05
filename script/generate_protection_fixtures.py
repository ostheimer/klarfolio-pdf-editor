#!/usr/bin/env python3
"""Synthetic protection fixtures. Requires pypdf 6.10, cryptography 50, openssl.

Run from any directory. Encryption IVs and the ephemeral signing key intentionally
vary; reproduce semantics, not identical ciphertext. No private key is saved.
"""
from datetime import datetime, timezone
from pathlib import Path
import io
import subprocess
import tempfile

from pypdf import PdfWriter
from pypdf.constants import UserAccessPermissions as P
from pypdf.generic import (ArrayObject, ByteStringObject, DictionaryObject,
                          NameObject, NumberObject, TextStringObject)
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives.serialization import pkcs7
from cryptography.x509.oid import NameOID

ROOT = Path(__file__).resolve().parent.parent / 'TestFixtures'
USER = 'klarfolio-test-open'
OWNER = 'klarfolio-test-owner'


def base():
    writer = PdfWriter(clone_from=ROOT / 'fixture-form.pdf')
    # Separate labels and values in the new fixtures; keep the legacy source
    # fixture byte-identical. The existing fixture's text field overlaps a label.
    for ref in writer.pages[0]['/Annots']:
        widget = ref.get_object()
        rect = {'KlarfolioName': [200, 720, 380, 748],
                'KlarfolioConsent': [200, 700, 216, 716]}.get(widget.get('/T'))
        if rect:
            widget[NameObject('/Rect')] = ArrayObject([NumberObject(n) for n in rect])
    writer.append(ROOT / 'fixture-merge-2-pages.pdf')
    return writer


for name, password, permissions in [
    ('password', USER, P(-1)),
    ('restricted', '', P(0)),
    ('form-only', '', P.FILL_FORM_FIELDS),
    ('assembly-only', '', P.ASSEMBLE_DOC),
    ('comment-only', '', P.ADD_OR_MODIFY),
]:
    writer = base()
    writer.encrypt(password, OWNER, permissions_flag=permissions, algorithm='AES-128')
    writer.write(ROOT / f'fixture-{name}.pdf')


def signature_field(writer, value=None):
    field = DictionaryObject({
        NameObject('/FT'): NameObject('/Sig'),
        NameObject('/Type'): NameObject('/Annot'),
        NameObject('/Subtype'): NameObject('/Widget'),
        NameObject('/T'): TextStringObject('SyntheticSignature'),
        NameObject('/Rect'): ArrayObject([NumberObject(n) for n in [40, 80, 300, 110]]),
        NameObject('/P'): writer.pages[0].indirect_reference,
    })
    if value is not None:
        field[NameObject('/V')] = writer._add_object(value)
    ref = writer._add_object(field)
    writer.pages[0]['/Annots'].append(ref)
    writer.root_object['/AcroForm']['/Fields'].append(ref)


writer = base()
signature_field(writer)
writer.write(ROOT / 'fixture-empty-signature.pdf')

writer = base()
writer.pages[0]['/Annots'].append(writer._add_object(DictionaryObject({
    NameObject('/Type'): NameObject('/Annot'),
    NameObject('/Subtype'): NameObject('/FreeText'),
    NameObject('/Rect'): ArrayObject([NumberObject(n) for n in [40, 80, 420, 130]]),
    NameObject('/Contents'): TextStringObject('Unterschrift - /Type /Sig /ByteRange [0 1 2 3]'),
    NameObject('/DA'): TextStringObject('/Helv 12 Tf 0 g'),
})))
writer.write(ROOT / 'fixture-signature-placeholder.pdf')

writer = base()
signature_field(writer, DictionaryObject({
    NameObject('/Type'): NameObject('/Sig'),
    NameObject('/Filter'): NameObject('/Adobe.PPKLite'),
    NameObject('/SubFilter'): NameObject('/adbe.pkcs7.detached'),
    NameObject('/ByteRange'): ArrayObject([NumberObject(9999999999) for _ in range(4)]),
    NameObject('/Contents'): ByteStringObject(bytes(8192)),
    NameObject('/M'): TextStringObject('D:20260905000000Z'),
}))
buffer = io.BytesIO()
writer.write(buffer)
data = buffer.getvalue()
start = data.index(b'<0000000000000000')
end = data.index(b'>', start) + 1
sentinel = b'[ 9999999999 9999999999 9999999999 9999999999 ]'
byte_range = f'[ 0 {start} {end} {len(data) - end} ]'.encode()
assert sentinel in data
data = data.replace(sentinel, byte_range.ljust(len(sentinel)), 1)
content = data[:start] + data[end:]
key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, 'Klarfolio Synthetic Test Only')])
cert = (x509.CertificateBuilder().subject_name(name).issuer_name(name)
        .public_key(key.public_key()).serial_number(22)
        .not_valid_before(datetime(2026, 1, 1, tzinfo=timezone.utc))
        .not_valid_after(datetime(2036, 1, 1, tzinfo=timezone.utc))
        .sign(key, hashes.SHA256()))
signature = (pkcs7.PKCS7SignatureBuilder().set_data(content)
             .add_signer(cert, key, hashes.SHA256())
             .sign(serialization.Encoding.DER, [pkcs7.PKCS7Options.DetachedSignature,
                                                pkcs7.PKCS7Options.Binary,
                                                pkcs7.PKCS7Options.NoAttributes]))
encoded = signature.hex().encode()
assert len(encoded) <= end - start - 2
data = data[:start + 1] + encoded.ljust(end - start - 2, b'0') + data[end - 1:]
with tempfile.TemporaryDirectory(prefix='klarfolio-signature-verification-') as temp:
    temp = Path(temp)
    (temp / 'signature.der').write_bytes(signature)
    (temp / 'content.bin').write_bytes(content)
    subprocess.run(['openssl', 'cms', '-verify', '-binary', '-inform', 'DER',
                    '-in', str(temp / 'signature.der'), '-content', str(temp / 'content.bin'),
                    '-noverify', '-out', str(temp / 'verified.bin')], check=True)
    assert (temp / 'verified.bin').read_bytes() == content
(ROOT / 'fixture-signed.pdf').write_bytes(data)
print('Generated 8 synthetic fixtures; detached CMS signature verified (no trust validation).')

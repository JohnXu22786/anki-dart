# SPDX-License-Identifier: AGPL-3.0-or-later
import unittest

from tool.check_package import generated_spdx_error, proto_license_error
from tool.normalize_generated import normalize_source


AGPL = "AGPL-3.0-or-later"
PROTO_HEADER = (
    "// Copyright: Ankitects Pty Ltd and contributors\n"
    "// License: GNU AGPL, version 3 or later; http://www.gnu.org/licenses/agpl.html\n"
)


class SpdxPipelineTest(unittest.TestCase):
    def test_normalizer_adds_one_agpl_tag(self):
        generated = "// Generated code. Do not modify.  \n\nclass Example {}\n\n"

        normalized = normalize_source(generated)

        self.assertTrue(normalized.startswith(f"// SPDX-License-Identifier: {AGPL}\n"))
        self.assertTrue(normalized.endswith("class Example {}\n"))
        self.assertNotIn("{}  ", normalized)

    def test_normalizer_is_idempotent(self):
        generated = f"// SPDX-License-Identifier: {AGPL}\n// generated\n"

        self.assertEqual(normalize_source(normalize_source(generated)), normalize_source(generated))

    def test_normalizer_rejects_conflicting_license(self):
        generated = "// SPDX-License-Identifier: MIT\n// generated\n"

        with self.assertRaisesRegex(ValueError, "MIT"):
            normalize_source(generated)

    def test_generated_checker_requires_only_the_expected_tag(self):
        self.assertIsNone(generated_spdx_error(f"// SPDX-License-Identifier: {AGPL}\nclass Example {{}}\n"))
        self.assertIsNotNone(generated_spdx_error("// generated\nclass Example {}\n"))
        self.assertIsNotNone(generated_spdx_error("// SPDX-License-Identifier: MIT\nclass Example {}\n"))
        self.assertIsNotNone(
            generated_spdx_error(
                f"// SPDX-License-Identifier: {AGPL}\n// SPDX-License-Identifier: MIT\nclass Example {{}}\n"
            )
        )

    def test_proto_checker_accepts_upstream_header_and_headerless_manifest_entry(self):
        self.assertIsNone(proto_license_error(PROTO_HEADER + 'syntax = "proto3";\n', AGPL, 'generic.proto'))

    def test_proto_checker_rejects_missing_or_conflicting_source_license(self):
        self.assertIsNotNone(proto_license_error(PROTO_HEADER + 'syntax = "proto3";\n', None, 'generic.proto'))
        self.assertIsNone(proto_license_error('syntax = "proto3";\n', AGPL, 'ankidroid.proto'))
        self.assertIsNotNone(
            proto_license_error(
                "// SPDX-License-Identifier: MIT\n" + PROTO_HEADER + 'syntax = "proto3";\n',
                AGPL,
                'generic.proto',
            )
        )


if __name__ == "__main__":
    unittest.main()

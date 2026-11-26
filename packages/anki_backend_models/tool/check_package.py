#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Check this package's pinned upstream source and standalone license metadata."""

from hashlib import sha256
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCE_COMMIT = "e64c6b1aee3e8d668fb8bbe084beada8e070d985"
UNICODE_CASE_FOLDING = "9c772627c6ee77eea6a17b42927b8ee28ca05dc65d6a511062104baaf3d12294"
SOURCE_HASHES = {
    "rslib/src/storage/card/mod.rs": "423e00d89092a4f1ab8e03923bfa8db455748043276c7bd647e2704bfcf7da95",
    "rslib/src/browser_table.rs": "e5749150fefa0955629c635c2e55b2f934fcb00d3e461c9e8426aa4e77fea573",
    "rslib/src/card_rendering/mod.rs": "e42521c0a36dc06898cc6d1e472a05051a77a418910d1ef362a67f3d04f7246a",
    "rslib/src/card_rendering/parser.rs": "b85262f63e71c0d97389913e6163a9a99ef9fc30ba0a7860d724eada490ddcbd",
    "rslib/src/card_rendering/writer.rs": "cc161fd95826a8fe39eefe83566fbfa1e5d8c685fb84c6b765baf89bc12983e1",
    "rslib/src/notetype/render.rs": "e5652c4ba780534e33e9d361b61b4124c33939b90a3b884e98ef6521f176bf29",
    "rslib/src/template_filters.rs": "3b7d392fd119498ea1dcee1d44492884b2d9257808da76c5d037289555b7d8ca",
    "rslib/src/card/mod.rs": "cfe294e1c65394f0b5c627b1e029b9d88bdf63de6fb3a29ba5a0253cd3f61ba9",
    "rslib/src/cloze.rs": "478a35d1248be262ed2d0941202ac8f201c7eb0a5c57b7198d3ace03898fd1c5",
    "rslib/src/card/service.rs": "8ddddbf879e08cb70ea00e9f00ac6c98f9f3988af65c48598a6cbb2fc11558b6",
    "rslib/src/notes/mod.rs": "5df79b58906206a87c5a28a06f886227df74e6a65d061d2cb915d35b34d35893",
    "rslib/src/notetype/mod.rs": "4f133ddf970d954e80cf3352d5bd91bf73418a1d71eaa1fb863218569d4198cb",
    "rslib/src/notetype/stock.rs": "a2f5175e8dcff92c01bfc09ed30f0e085253b8de01be6769019e505f5704ae15",
    "rslib/src/image_occlusion/notetype.rs": "89bd6609de21422b5e8de1f7cba0f693b24476a85401dc89ff7812b48375eff9",
    "rslib/src/image_occlusion/notetype.css": "18637cbc7996bb06e803239f99cd56befa7707035fa05f63ca44f62aba83e9ad",
    "rslib/src/notetype/cloze_styling.css": "17d12d52e6321d5f17be18911f47433110d39e9a52d23eeb13bfe7787932639d",
    "rslib/src/notetype/header.tex": "9e1dcea96178f505ec330c20efea94e11350d671f245612bc8cae1960e9223b7",
    "rslib/src/notetype/styling.css": "e50d4c220958517e9418a1bfe849fe0f3fc74a507600aafe00fc9d7a94733740",
    "rslib/src/notetype/service.rs": "6fc566d68509e21ae4b294bf6fe45c3f458d81eb459c454e2faf9c6c19c44b9f",
    "rslib/src/notetype/fields.rs": "531d82f2917cab0d27828e2477ee51f4f533e9f81a499dcb2bc5632be6262a3a",
    "rslib/src/notetype/templates.rs": "b04ee6f16a250d5ee5649e6ef122f5ecfeab5d7aebaf80d4d31093ca96e9b241",
    "rslib/src/decks/mod.rs": "dc5a90c3465b7216b6ad1e42a0c44a2d18a99beea777023adcb63cb4abdf38d4",
    "rslib/src/decks/name.rs": "0a4e33f5a92d2c479c4cbd59664b0de30a50a41453dbe131fc9c809f5afc5f4d",
    "rslib/src/decks/service.rs": "87c0df5a0a7f1307a55f46daac235868a994e96e9a7ae34f7322bb6c3d11bed5",
    "rslib/src/deckconfig/mod.rs": "1b85b99ae9188b5f8d2ccb6a23930bc636f86c1a775a564cd24d1017fcebcfac",
    "rslib/src/deckconfig/service.rs": "58b9d4da7924cfa95cec66061fe1b75be38c5109df710e6c01d22cbb0bceb4be",
    "rslib/src/media/mod.rs": "bcf4529fbf244f506221cc45e0683f432e1366dacebf176cf2dda1616e581424",
    "rslib/src/sync/media/database/client/mod.rs": "e07639f5018eac52b29657dda99eb9e16f186e734b6b3e530c75f6af93059e81",
    "rslib/src/config/mod.rs": "4d288b43ebfb365e083f2fcf352e6c6a87b973c0e8fea8aedcef872db8bd03eb",
    "rslib/src/revlog/mod.rs": "e528d4708a21ae2da87705434249e2e842155e3a34161d556979e5d611b63faa",
    "rslib/src/stats/service.rs": "bd65f462a7af8a3dfa1cb3c622fc6324d0e8ddca6535f6b20b1e3908efb3895e",
    "rslib/src/text.rs": "2b60699e1c6ad478baf80bfa50a85e9772f40279400d62c84b071c72945b1762",
    "rslib/src/storage/note/mod.rs": "e875a63c641393c0a6904872bd55ebe164a4eceff8aa07686ca246fe6d54de23",
    "rslib/src/tags/mod.rs": "de82a2b8d9fe292039a3adf1335f916368ddb6e63639a59d1a4e0a490dc2a26f",
    "rslib/src/template.rs": "59e5d111308ffd61a818704ffda53922e3600ed435e4b220ce32adbecdf460e3",
    "proto/anki/stats.proto": "5b22c0aa2133b68eefc93964299668732941ee3688140cd98430b033ee567ea4",
    "proto/anki/notes.proto": "cbd4cb07075d51d7854c94bccf0b00a47f5b7f5b8ac5be1246f7ddcf003799f6",
    "rslib/src/scheduler/states/review.rs": "57ed79be2d29e6185ecf7c0444e3f21929ce5b86b1e8d5b60aacf90c9fdb494d",
    "rslib/src/scheduler/queue/entry.rs": "70f10d3800a8da49319df7b91aa4a4a3464a5a1ea20fca6f2c9ea54e7b829e5c",
    "rslib/src/scheduler/queue/learning.rs": "65e7543e3cf0a124013c2ca8bb67ca11a40242093c1acf167fb4c2773af44464",
    "rslib/src/scheduler/queue/builder/intersperser.rs": "698bd875580f932975b38c1d755a40be2b28bed14f6ba07721a208399cd98a1d",
    "rslib/src/scheduler/queue/builder/gathering.rs": "f98edfafb21148077cb7ec89ccb7e5060cce2d474b329ee54ba1c9fa7d8d102a",
    "rslib/src/scheduler/queue/builder/burying.rs": "47d3beb27b6442b77e1b5709befbbf0fef506aa51dfb65f9dd57fabda48ea80e",
    "rslib/src/scheduler/queue/builder/mod.rs": "c4421df5bd8065ea679b0de41fb400450821e9f8a98c7d8da40e0b95e5fb9103",
    "rslib/src/scheduler/queue/builder/sorting.rs": "d7edb269c27552f2d51f67f698d70e60ba12aaad965bfb26e6b7586abdec6a9c",
    "rslib/src/scheduler/queue/mod.rs": "ad36a76e8abd51840f9a9d2d029f04a9bede5fe55f4cb9a695c3718c26184ac8",
    "rslib/src/decks/limits.rs": "d8de3c382f4f4e130699dd18bbc46b6a93664fc97ef8d45448479b4fb165af27",
    "rslib/src/scheduler/states/load_balancer.rs": "cad7e0a3805c189440bdeaaba9705f0be5af05c32d96c3d7c86f0c55f5959f91",
    "rslib/src/scheduler/states/fuzz.rs": "30a33e2e522ebcb56ca434a897f66209fcb4284065115ee031def73097343105",
    "rslib/src/scheduler/states/mod.rs": "f4247b73f39403a1f8eb423d52bec91bf3e7f6a005f1b93767a24a0a0ee8f7a9",
    "rslib/src/scheduler/states/steps.rs": "3baf0c2c125599998929dfb292e91d07202458977d67f906a27b632776eaf4fa",
    "rslib/src/scheduler/states/learning.rs": "3c2a6a9c30e340499658d754af8b830880763312d73ce8482bbb7e1925de9799",
    "rslib/src/scheduler/states/relearning.rs": "411b1ded66ef2b9927ba85f17416301f5afd66108bd1864ea0d0b4578bc54808",
    "rslib/src/scheduler/states/new.rs": "72fa01fa70e0247c63f91d908698d1db9bc0d063e6b3c7a20b206d308e1af810",
    "rslib/src/scheduler/states/normal.rs": "939d8157473cd445183f7b6f7179c87499667cb1057f47d728a6b4c03806c2c1",
    "rslib/src/scheduler/states/interval_kind.rs": "88803a0e2f3f974b3d9da1f8dd196dc709f8f8706776efd1c6daab06a8eade7f",
    "rslib/src/scheduler/states/filtered.rs": "e200cfa0719882e7092e345d0be8e2357d9d8058be3da11601e81ffa4ebe29f4",
    "rslib/src/scheduler/states/rescheduling_filter.rs": "68fd6b4983317889cf29fd9273d59970182f42d5774a4f94bfb34f912408559a",
    "rslib/src/scheduler/states/preview_filter.rs": "ecc8a41bb4ed62be853e58dacc9ab0d296fbce27404ff408e3a7fa3148dde98f",
    "rslib/src/scheduler/answering/revlog.rs": "67021777f00a56ed93771bec8cf21f27faf6eda2c5b09c5d5640eb9c2cec42aa",
    "proto/anki/scheduler.proto": "9ebdd150185cdaccef2a7957481361b869344e573cce4dc0be77489cac7b71e3",
    "rslib/src/scheduler/answering/current.rs": "1d8a18daf1ff3bf6e4252fbe58c3ff79ced4da8bbf75093b783b0dbd32ddbf4e",
    "rslib/src/scheduler/answering/mod.rs": "7f921fb18f6ea7adecb8c6a2d6cc53abfd9cae1f1dc15104b9704ec874ee5873",
    "rslib/src/scheduler/answering/preview.rs": "19cf1867554b0a237d8cb89bcee05f987dbf799e9b61e7267f859057e6d5fc4e",
    "rslib/src/scheduler/filtered/card.rs": "6aca7e9b55088f43d981eaafa8a02c5de538cf3c7e1c13640e3565de6ee4fd13",
    "rslib/src/scheduler/timing.rs": "a9aeea597aa76b57a90bf91124d4245bde91c672f60e56337460a60300795f17",
    "rslib/src/scheduler/answering/learning.rs": "c6c744d494a7f54d5efb8c2d5e98a74c92016c84d10773437b16414c8840cacc",
    "rslib/src/scheduler/states/review.rs": "57ed79be2d29e6185ecf7c0444e3f21929ce5b86b1e8d5b60aacf90c9fdb494d",
    "rslib/src/scheduler/states/fuzz.rs": "30a33e2e522ebcb56ca434a897f66209fcb4284065115ee031def73097343105",
    "rslib/src/scheduler/states/mod.rs": "f4247b73f39403a1f8eb423d52bec91bf3e7f6a005f1b93767a24a0a0ee8f7a9",
    "rslib/src/scheduler/states/steps.rs": "3baf0c2c125599998929dfb292e91d07202458977d67f906a27b632776eaf4fa",
    "rslib/src/scheduler/fsrs/memory_state.rs": "e5b494807a5bd94e09e80829399669808cbd6377786dce6567ab557b18d1a799",
    "rslib/src/scheduler/fsrs/params.rs": "fd04b48ca637f9e197eea84de809767fade3e1a449114cc851891300b0068d29",
    "fsrs-5.2.0/src/model.rs": "2d86e7463e1a76dbee47bf787707d2e74f3576d996f96ffe79c7e922c6ca4633",
    "fsrs-5.2.0/src/inference.rs": "8576fff074614a702a04ed02c459422eb2d9ca284ea9a66143d7b32abcc6c09f",
    "fsrs-5.2.0/src/parameter_clipper.rs": "8b9f3f62b7ad02cf54a4bf1263fc8c6e6615b481082440bf660acb557901b113",
    "fsrs-5.2.0/src/parameter_initialization.rs": "a48564d946c3bb2a67524d96b98d38dafb2f6dbdd6a0dcc9ac5c5b3a627b10d6",
    "fsrs-5.2.0/src/simulation.rs": "5436a78c825ce863edf8e234731a499c328e14413b2e09433d67a093fc6a5e69",
}
THIRD_PARTY_HASHES = {
    "htmlescape-0.3.1.crate": "e9025058dae765dee5070ec375f591e2ba14638c63feff74f13805a72e523163",
    "htmlescape-0.3.1/src/entities.rs": "a332c354a31bc57150f24987eb23324d3b87e8a33dda0ca553474d5c955b20d7",
    "fsrs-5.2.0.crate": "cab5f80c16d1d07e492a6828478ecb9f379f142ba6f19fa3b7955edd180ddc2e",
    "rand-0.9.4.crate": "44c5af06bb1b7d3216d91932aed5265164bf384dc89cd6ba05cf59a35f5f76ea",
    "rand_chacha-0.9.0.crate": "d3022b5f1df60f26e1ffddd6c66e8aa15de382ae63b3a0c1bfc0e4d3e3f325cb",
    "rand_core-0.9.3.crate": "99d9a13982dcf210057a8a78572b2217b667c3beacbf3a0d8b454f6f82837d38",
    "ppv-lite86-0.2.21.crate": "85eae3c4ed2f50dcfe72643da4befc30deadb458a9b590d720cde2f2b1e97da9",
}

def main() -> int:
    errors: list[str] = []
    notice = ROOT / "NOTICE.md"
    notice_text = notice.read_text(encoding="utf-8") if notice.is_file() else ""
    if SOURCE_COMMIT not in notice_text:
        errors.append("NOTICE.md: pinned Anki Core source commit is missing")
    if "Ankitects Pty Ltd and contributors" not in notice_text:
        errors.append("NOTICE.md: upstream attribution is missing")
    if "GNU Affero" not in notice_text or "Public License" not in notice_text:
        errors.append("NOTICE.md: AGPL notice is missing")

    source_record = ROOT / "SOURCE.sha256"
    actual: dict[str, str] = {}
    if source_record.is_file():
        for line in source_record.read_text(encoding="utf-8").splitlines():
            match = re.fullmatch(
                r"([0-9a-f]{64})  ((?:rslib/src/[a-z_/]+\.(?:rs|css|tex)|proto/anki/[a-z_/]+\.proto|fsrs-5\.2\.0/src/[a-z_]+\.rs))", line
            )
            if not match:
                errors.append(f"SOURCE.sha256: invalid entry {line!r}")
                continue
            if match.group(2) in actual:
                errors.append(f"SOURCE.sha256: duplicate entry for {match.group(2)}")
            actual[match.group(2)] = match.group(1)
        if actual != SOURCE_HASHES:
            errors.append("SOURCE.sha256: entries do not match the pinned upstream file hashes")
    else:
        errors.append("SOURCE.sha256: source digest manifest is missing")

    third_party_manifest = ROOT / "THIRD_PARTY_SOURCE.sha256"
    third_party_actual: dict[str, str] = {}
    if third_party_manifest.is_file():
        for line in third_party_manifest.read_text(encoding="utf-8").splitlines():
            match = re.fullmatch(r"([0-9a-f]{64})  (.+)", line)
            if not match:
                errors.append(f"THIRD_PARTY_SOURCE.sha256: invalid entry {line!r}")
                continue
            third_party_actual[match.group(2)] = match.group(1)
        if third_party_actual != THIRD_PARTY_HASHES:
            errors.append("THIRD_PARTY_SOURCE.sha256: third-party crate hashes are incorrect")
    else:
        errors.append("THIRD_PARTY_SOURCE.sha256: third-party source digest manifest is missing")
    if not (ROOT / "LICENSES" / "Apache-2.0.txt").is_file():
        errors.append("LICENSES/Apache-2.0.txt: htmlescape data license text is missing")
    rand_apache = ROOT / "LICENSES" / "Apache-2.0-Rand.txt"
    if not rand_apache.is_file() or "END OF TERMS AND CONDITIONS" not in rand_apache.read_text(encoding="utf-8"):
        errors.append("LICENSES/Apache-2.0-Rand.txt: rand crate Apache-2.0 license text is missing")
    rand_mit = ROOT / "LICENSES" / "MIT-Rand.txt"
    if not rand_mit.is_file() or "Copyright 2018 Developers of the Rand project" not in rand_mit.read_text(encoding="utf-8"):
        errors.append("LICENSES/MIT-Rand.txt: rand crate MIT license text is missing")
    fsrs_license = ROOT / "LICENSES" / "BSD-3-Clause-FSRS.txt"
    if not fsrs_license.is_file() or "Copyright (c) 2023, Open Spaced Repetition" not in fsrs_license.read_text(encoding="utf-8"):
        errors.append("LICENSES/BSD-3-Clause-FSRS.txt: fsrs 5.2.0 BSD-3-Clause license text is missing")

    unicode_manifest = ROOT / "UNICODE_CASEFOLD.sha256"
    expected_unicode_record = (
        f"{UNICODE_CASE_FOLDING}  Unicode 12.1.0 CaseFolding.txt\n"
    )
    if not unicode_manifest.is_file() or unicode_manifest.read_text(
        encoding="utf-8"
    ) != expected_unicode_record:
        errors.append("UNICODE_CASEFOLD.sha256: Unicode folding data hash is incorrect")

    license_text = (ROOT / "LICENSE").read_text(encoding="utf-8") if (ROOT / "LICENSE").is_file() else ""
    if "GNU AFFERO GENERAL PUBLIC LICENSE" not in license_text or "Version 3" not in license_text:
        errors.append("LICENSE: complete GNU AGPL version 3 text is missing")
    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    if not re.search(r"^license:\s*AGPL-3\.0-or-later\s*$", pubspec, re.MULTILINE):
        errors.append("pubspec.yaml: license must be AGPL-3.0-or-later")

    for path in sorted((ROOT / "lib").rglob("*.dart")):
        text = path.read_text(encoding="utf-8")
        identifier = (
            "Apache-2.0" if path.name == "html_entities.dart" else "AGPL-3.0-or-later"
        )
        if not text.startswith(f"// SPDX-License-Identifier: {identifier}\n"):
            errors.append(f"{path.relative_to(ROOT)}: {identifier} SPDX header is missing")
        if "import 'dart:io'" in text or 'import "dart:io"' in text:
            errors.append(f"{path.relative_to(ROOT)}: VM-only dart:io import is forbidden")
    for directory in ("test", "tool"):
        for path in sorted((ROOT / directory).rglob("*.dart")):
            if not path.read_text(encoding="utf-8").startswith(
                "// SPDX-License-Identifier: AGPL-3.0-or-later\n"
            ):
                errors.append(f"{path.relative_to(ROOT)}: AGPL SPDX header is missing")
    if not (ROOT / "lib" / "anki_backend_models.dart").is_file():
        errors.append("lib/anki_backend_models.dart: public model export is missing")

    if errors:
        print("Model package validation failed:", file=sys.stderr)
        print("\n".join(f"- {error}" for error in errors), file=sys.stderr)
        return 1
    print("Validated pinned Anki model source hashes, AGPL metadata, and platform-neutral imports.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

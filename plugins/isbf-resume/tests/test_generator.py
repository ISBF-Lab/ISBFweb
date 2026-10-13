import base64
import io
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from zipfile import ZipFile

from lxml import etree
from PIL import Image
from pypdf import PdfWriter

from resume_generator import ValidationError, build_docx, main, normalize_payload, render_preview


def minimal():
    return {
        "version": 1,
        "template": "blue-gold",
        "basic": {"name": "示例用户", "phone": "+86 138 0000 0000", "email": "name@example.com"},
    }


def document_xml(path):
    with ZipFile(path) as archive:
        return etree.fromstring(archive.read("word/document.xml"))


def document_text(path):
    return "".join(document_xml(path).xpath("//*[local-name()='t']/text()"))


class GeneratorTests(unittest.TestCase):
    def test_document_language_defaults_to_chinese_and_rejects_unsupported_values(self):
        self.assertEqual(normalize_payload(minimal())["language"], "zh_CN")
        for language in ("fr", "", None, [], {}):
            with self.subTest(language=language):
                with self.assertRaises(ValidationError) as result:
                    normalize_payload({**minimal(), "language": language})
                self.assertIn("language", result.exception.errors)

    def test_english_headings_dates_and_labels_preserve_every_user_entry(self):
        data = {**minimal(), "language": "en"}
        data["basic"].update(highest_education="Example University · Computing · BSc",
                             portfolio_links="https://example.com/work",
                             linkedin="https://www.linkedin.com/in/example/",
                             work_permit="No sponsorship required")
        data["education"] = [{"school": "Example University", "courses": "Algorithms",
                              "start_month": "2022-09", "end_month": "2027-06", "ongoing": True}]
        data["experience"] = [{"company": "Example Company", "department": "Engineering", "ongoing": True}]
        data["projects"] = [{"name": "A & B <项目>", "technology": "Python",
                             "link": "https://example.com/project", "details": "保留原文 & 50%\nSecond original line"}]
        data["activities"] = [{"name": "Student society", "ongoing": True}]
        data["skills"] = [{"name": "Python", "issuer": "Example Institute"}]
        data["honors"] = [{"name": "Competition award", "issuer": "Example University"}]
        data["summary"] = {"text": "Original profile wording."}
        with tempfile.TemporaryDirectory() as temporary:
            text = document_text(build_docx(data, Path(temporary) / "english.docx"))
        for label in ("Resume", "Personal information", "Name: ", "Phone: ", "Email: ",
                      "Education", "Work and internship experience", "Projects and research",
                      "Campus and volunteer experience", "Skills and certifications", "Awards and honors",
                      "Profile", "Relevant coursework: ", "Department / business area: ",
                      "Technologies / methods: ", "Link: ", "Institution: ", "Present", "2027.06 (expected)"):
            self.assertIn(label, text)
        for original in ("示例用户", "A & B <项目>", "保留原文 & 50%", "Second original line", data["summary"]["text"]):
            self.assertIn(original, text)
        for chinese_label in ("基本信息", "教育背景", "工作与实习经历", "相关课程：", "至今", "（预计）"):
            self.assertNotIn(chinese_label, text)

    def test_english_template_packages_differ_only_in_accent_color(self):
        data = {**minimal(), "language": "en", "projects": [{"name": "Example project", "details": "Original wording."}]}
        with tempfile.TemporaryDirectory() as temporary:
            gold = build_docx(data, Path(temporary) / "gold.docx")
            gray = build_docx({**data, "template": "blue-gray"}, Path(temporary) / "gray.docx")
            with ZipFile(gold) as gold_zip, ZipFile(gray) as gray_zip:
                self.assertEqual(gold_zip.namelist(), gray_zip.namelist())
                for filename in gold_zip.namelist():
                    self.assertEqual(gold_zip.read(filename).replace(b"C19F67", b"A5A5A5"), gray_zip.read(filename))

    def test_required_fields_are_enforced_server_side(self):
        with self.assertRaises(ValidationError) as result:
            normalize_payload({"basic": {}})
        self.assertEqual(set(result.exception.errors), {"basic.name", "basic.phone", "basic.email"})

    def test_international_phone_and_nonempty_record(self):
        data = minimal()
        data["basic"]["phone"] = "+1 (415) 555-0123"
        data["projects"] = [{"details": "独立完成登录界面"}]
        with self.assertRaises(ValidationError) as result:
            normalize_payload(data)
        self.assertIn("projects.0.name", result.exception.errors)
        self.assertNotIn("basic.phone", result.exception.errors)

    def test_phone_extension_is_preserved_and_garbage_is_rejected(self):
        data = minimal()
        data["basic"]["phone"] = "+86 10 1234 5678 ext. 123"
        self.assertEqual(normalize_payload(data)["basic"]["phone"], data["basic"]["phone"])
        data["basic"]["phone"] = "abc12345"
        with self.assertRaises(ValidationError) as result:
            normalize_payload(data)
        self.assertIn("basic.phone", result.exception.errors)

    def test_unknown_imported_content_is_not_silently_discarded(self):
        data = minimal()
        data["patents"] = [{"name": "用户输入的专利"}]
        with self.assertRaises(ValidationError) as result:
            normalize_payload(data)
        self.assertIn("document", result.exception.errors)

    def test_date_order_and_current_status_are_consistent(self):
        data = minimal()
        data["experience"] = [{"company": "示例单位", "start_month": "2025-06", "end_month": "2024-06"}]
        with self.assertRaises(ValidationError) as result:
            normalize_payload(data)
        self.assertIn("experience.0.end_month", result.exception.errors)
        data["experience"][0].update(start_month="2023-06", ongoing=True)
        with self.assertRaises(ValidationError):
            normalize_payload(data)

    def test_empty_modules_leave_no_heading_or_reference_placeholders(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = build_docx(minimal(), Path(temporary) / "resume.docx")
            text = document_text(target)
            self.assertIn("name@example.com", text)
            self.assertNotIn("教育背景", text)
            self.assertNotIn("自我评价", text)
            self.assertNotIn("20xx", text)
            self.assertFalse(document_xml(target).xpath("//*[local-name()='drawing']"))

    def test_user_text_is_preserved_and_xml_escaped(self):
        data = minimal()
        data["projects"] = [{"name": "A & B <项目>", "details": "保留用户原文 & 50%\n第二行原文：中英混排 GitHub"}]
        data["summary"] = {"text": "用户原文：不是系统生成的评价。"}
        with tempfile.TemporaryDirectory() as temporary:
            target = build_docx(data, Path(temporary) / "resume.docx")
            text = document_text(target)
            self.assertIn("A & B <项目>", text)
            self.assertIn("保留用户原文 & 50%", text)
            self.assertIn("第二行原文：中英混排 GitHub", text)
            self.assertIn(data["summary"]["text"], text)

    def test_both_templates_change_only_color(self):
        data = minimal()
        with tempfile.TemporaryDirectory() as temporary:
            gold = build_docx(data, Path(temporary) / "gold.docx")
            data["template"] = "blue-gray"
            gray = build_docx(data, Path(temporary) / "gray.docx")
            with ZipFile(gold) as first, ZipFile(gray) as second:
                self.assertEqual(first.namelist(), second.namelist())
                for name in first.namelist():
                    self.assertEqual(first.read(name).replace(b"C19F67", b"A5A5A5"), second.read(name), name)

    def test_real_photo_is_bounded_without_cropping(self):
        image = Image.new("RGB", (120, 1200), color="white")
        buffer = io.BytesIO()
        image.save(buffer, "PNG")
        data = minimal()
        data["basic"]["photo"] = "data:image/png;base64," + base64.b64encode(buffer.getvalue()).decode()
        with tempfile.TemporaryDirectory() as temporary:
            target = build_docx(data, Path(temporary) / "resume.docx")
            size = document_xml(target).xpath("//*[local-name()='extent']")[0]
            self.assertLessEqual(int(size.get("cy")), 35 * 36000 + 1)
            self.assertAlmostEqual(int(size.get("cx")) / int(size.get("cy")), 0.1, places=4)

    def test_phone_camera_orientation_is_respected(self):
        image = Image.new("RGB", (1200, 120), color="white")
        metadata = image.getexif()
        metadata[274] = 6
        buffer = io.BytesIO()
        image.save(buffer, "JPEG", exif=metadata)
        data = minimal()
        data["basic"]["photo"] = "data:image/jpeg;base64," + base64.b64encode(buffer.getvalue()).decode()
        with tempfile.TemporaryDirectory() as temporary:
            target = build_docx(data, Path(temporary) / "resume.docx")
            size = document_xml(target).xpath("//*[local-name()='extent']")[0]
            self.assertAlmostEqual(int(size.get("cx")) / int(size.get("cy")), 0.1, places=4)
            self.assertLessEqual(int(size.get("cy")), 35 * 36000 + 1)

    def test_invalid_photo_and_unsafe_links_are_rejected(self):
        data = minimal()
        data["basic"]["photo"] = "data:image/svg+xml;base64,PHN2Zz4="
        data["basic"]["linkedin"] = "javascript:alert(1)"
        with self.assertRaises(ValidationError) as result:
            normalize_payload(data)
        self.assertIn("basic.photo", result.exception.errors)
        self.assertIn("basic.linkedin", result.exception.errors)


class PreviewTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.pdf = self.directory / "resume with spaces.pdf"

    def write_pdf(self, pages):
        writer = PdfWriter()
        for _ in range(pages):
            writer.add_blank_page(width=595, height=842)
        with self.pdf.open("wb") as stream:
            writer.write(stream)

    def renderer(self, filenames, image_format="PNG", returncode=0, size=(30, 50)):
        def run(command, **options):
            prefix = Path(command[-1])
            for filename in filenames:
                Image.new("RGB", size, "white").save(prefix.parent / filename, image_format)
            return subprocess.CompletedProcess(command, returncode, stdout=b"", stderr=b"")
        return run

    def test_all_pages_are_normalized_without_changing_pdf_content_or_timestamp(self):
        self.write_pdf(12)
        content, modified = self.pdf.read_bytes(), self.pdf.stat().st_mtime_ns
        names = [f"preview-{page:02}.png" for page in reversed(range(1, 13))]
        with patch("resume_generator.shutil.which", return_value="pdftoppm"), patch(
            "resume_generator.subprocess.run", side_effect=self.renderer(names)
        ) as converter:
            files = render_preview(self.pdf, 12)
        self.assertEqual(files, [f"preview-{page}.png" for page in range(1, 13)])
        command, options = converter.call_args.args[0], converter.call_args.kwargs
        self.assertEqual(command[:-1], [str(Path("pdftoppm").resolve()), "-scale-to", "1400", "-png", str(self.pdf.resolve())])
        self.assertEqual(Path(command[-1]).name, "preview")
        self.assertEqual(options, {"capture_output": True, "timeout": 45, "check": False})
        for name in files:
            with Image.open(self.directory / name) as image:
                self.assertEqual(image.format, "PNG")
        self.assertEqual(self.pdf.read_bytes(), content)
        self.assertEqual(self.pdf.stat().st_mtime_ns, modified)

    def test_existing_preview_is_not_overwritten_or_sent_to_renderer(self):
        self.write_pdf(1)
        existing = self.directory / "preview-1.png"
        existing.write_bytes(b"existing preview")
        with patch("resume_generator.subprocess.run") as converter:
            with self.assertRaises(FileExistsError):
                render_preview(self.pdf, 1)
        converter.assert_not_called()
        self.assertEqual(existing.read_bytes(), b"existing preview")

    def test_page_gaps_and_duplicate_padded_numbers_are_rejected(self):
        self.write_pdf(2)
        for names in (["preview-1.png"], ["preview-1.png", "preview-3.png"],
                      ["preview-1.png", "preview-01.png"]):
            with self.subTest(names=names), patch("resume_generator.shutil.which", return_value="pdftoppm"), patch(
                "resume_generator.subprocess.run", side_effect=self.renderer(names)
            ):
                with self.assertRaises(RuntimeError):
                    render_preview(self.pdf, 2)
            self.assertEqual(list(self.directory.glob("preview-*.png")), [])

    def test_non_png_oversized_and_truncated_outputs_are_rejected(self):
        self.write_pdf(1)
        for image_format, size in (("JPEG", (30, 50)), ("PNG", (1401, 10))):
            with self.subTest(image_format=image_format, size=size), patch(
                "resume_generator.shutil.which", return_value="pdftoppm"
            ), patch("resume_generator.subprocess.run", side_effect=self.renderer(["preview-1.png"], image_format, size=size)):
                with self.assertRaises(RuntimeError):
                    render_preview(self.pdf, 1)
        def truncated(command, **options):
            (Path(command[-1]).parent / "preview-1.png").write_bytes(b"\x89PNG\r\n\x1a\n")
            return subprocess.CompletedProcess(command, 0)
        with patch("resume_generator.shutil.which", return_value="pdftoppm"), patch(
            "resume_generator.subprocess.run", side_effect=truncated
        ):
            with self.assertRaises(RuntimeError):
                render_preview(self.pdf, 1)
        self.assertEqual(list(self.directory.glob("preview-*.png")), [])

    def test_unexpected_output_filename_is_rejected(self):
        self.write_pdf(1)
        with patch("resume_generator.shutil.which", return_value="pdftoppm"), patch(
            "resume_generator.subprocess.run", side_effect=self.renderer(["preview-1.txt"])
        ):
            with self.assertRaises(RuntimeError):
                render_preview(self.pdf, 1)

    def test_renderer_timeout_failure_and_missing_binary_leave_no_published_preview(self):
        self.write_pdf(1)
        with patch("resume_generator.shutil.which", return_value="pdftoppm"), patch(
            "resume_generator.subprocess.run", side_effect=subprocess.TimeoutExpired("pdftoppm", 45)
        ):
            with self.assertRaisesRegex(RuntimeError, "超时"):
                render_preview(self.pdf, 1)
        with patch("resume_generator.shutil.which", return_value="pdftoppm"), patch(
            "resume_generator.subprocess.run", side_effect=self.renderer(["preview-1.png"], returncode=1)
        ):
            with self.assertRaises(RuntimeError):
                render_preview(self.pdf, 1)
        with patch("resume_generator.shutil.which", return_value=None), patch("resume_generator.subprocess.run") as converter:
            with self.assertRaisesRegex(RuntimeError, "未配置"):
                render_preview(self.pdf, 1)
        converter.assert_not_called()
        self.assertEqual(list(self.directory.glob("preview-*.png")), [])

    def test_atomic_publication_never_overwrites_a_file_created_after_validation(self):
        self.write_pdf(1)
        target = self.directory / "preview-1.png"
        original_link = os.link
        def raced_link(source, destination):
            target.write_bytes(b"raced existing preview")
            original_link(source, destination)
        with patch("resume_generator.shutil.which", return_value="pdftoppm"), patch(
            "resume_generator.subprocess.run", side_effect=self.renderer(["preview-1.png"])
        ), patch("resume_generator.os.link", side_effect=raced_link):
            with self.assertRaises(FileExistsError):
                render_preview(self.pdf, 1)
        self.assertEqual(target.read_bytes(), b"raced existing preview")

    def run_cli(self, flags):
        self.write_pdf(2)
        input_path = self.directory / "input.json"
        input_path.write_text(json.dumps(minimal()), encoding="utf-8")
        arguments = ["resume_generator.py", str(input_path), "--output-dir", str(self.directory), *flags]
        with patch("sys.argv", arguments), patch("sys.stdout", new_callable=io.StringIO) as output, patch(
            "resume_generator.convert_pdf", return_value=self.pdf
        ) as pdf_converter, patch(
            "resume_generator.render_preview", return_value=["preview-1.png", "preview-2.png"]
        ) as preview_converter:
            main()
        return json.loads(output.getvalue()), pdf_converter, preview_converter

    def test_default_cli_does_not_add_preview_or_call_renderer(self):
        output, pdf_converter, preview_converter = self.run_cli([])
        self.assertEqual(set(output), {"docx", "pdf", "pages"})
        self.assertEqual(output["pages"], 2)
        pdf_converter.assert_called_once()
        preview_converter.assert_not_called()

    def test_preview_cli_adds_ordered_relative_filenames(self):
        output, _, preview_converter = self.run_cli(["--preview"])
        self.assertEqual(output["preview_files"], ["preview-1.png", "preview-2.png"])
        self.assertEqual(output["pages"], 2)
        preview_converter.assert_called_once_with(self.pdf, 2)

    def test_docx_only_cli_does_not_convert_or_add_preview(self):
        output, pdf_converter, preview_converter = self.run_cli(["--docx-only"])
        self.assertEqual(set(output), {"docx"})
        pdf_converter.assert_not_called()
        preview_converter.assert_not_called()

    def test_preview_cannot_be_combined_with_docx_only(self):
        arguments = ["resume_generator.py", "missing-input.json", "--output-dir", str(self.directory), "--preview", "--docx-only"]
        with patch("sys.argv", arguments), patch("sys.stderr", new_callable=io.StringIO) as errors:
            with self.assertRaises(SystemExit) as result:
                main()
        self.assertEqual(result.exception.code, 2)
        self.assertIn("--preview", errors.getvalue())
        self.assertIn("--docx-only", errors.getvalue())


if __name__ == "__main__":
    unittest.main()

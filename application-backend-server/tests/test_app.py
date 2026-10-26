import unittest
from unittest.mock import patch, MagicMock
import os
import json
import pymysql

# Import Flask app under test
import sys
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

from app import app, validate_student_payload, get_db_connection


class AppServerTestCase(unittest.TestCase):
    def setUp(self):
        self.app = app
        self.app.config["TESTING"] = True
        self.client = self.app.test_client()

    def test_health_and_hello(self):
        # 1. Test /health
        res_health = self.client.get("/health")
        self.assertEqual(res_health.status_code, 200)
        data_health = res_health.get_json()
        self.assertEqual(data_health.get("status"), "ok")
        self.assertEqual(data_health.get("service"), "application-backend-server")

        # 2. Test /hello [Cơ bản #2]
        res_hello = self.client.get("/hello")
        self.assertEqual(res_hello.status_code, 200)
        self.assertEqual(res_hello.get_json(), {"message": "Hello from App Server!"})

    def test_student_json_from_any_cwd(self):
        # Test Review Focus 1: calling /student when cwd is different
        orig_cwd = os.getcwd()
        try:
            # Change CWD to repo root or parent dir
            os.chdir(os.path.dirname(BASE_DIR))
            res = self.client.get("/student")
            self.assertEqual(res.status_code, 200)
            data = res.get_json()
            self.assertIsInstance(data, list)
            self.assertEqual(len(data), 5)
            for item in data:
                self.assertIn("id", item)
                self.assertIn("name", item)
                self.assertIn("major", item)
                self.assertIn("gpa", item)
        finally:
            os.chdir(orig_cwd)

    @patch("app.get_jwks_for_realm")
    @patch("app.jwt.decode")
    def test_secure_missing_and_valid_token(self, mock_jwt_decode, mock_get_jwks):
        # 1. Missing Authorization header
        res_missing = self.client.get("/secure")
        self.assertEqual(res_missing.status_code, 401)
        self.assertIn("Missing Bearer token", res_missing.get_json().get("error", ""))

        # 2. Valid token mock
        mock_get_jwks.return_value = {"keys": []}
        mock_jwt_decode.return_value = {
            "preferred_username": "sv01",
            "iss": "http://authentication-identity-server:8080/realms/realm_sv001",
            "azp": "flask-app",
        }
        res_valid = self.client.get(
            "/secure", headers={"Authorization": "Bearer fake-jwt-token-123"}
        )
        self.assertEqual(res_valid.status_code, 200)
        data = res_valid.get_json()
        self.assertEqual(data.get("message"), "Secure resource OK")
        self.assertEqual(data.get("preferred_username"), "sv01")

    @patch("app.get_db_connection")
    def test_students_db_get(self, mock_get_conn):
        mock_cursor = MagicMock()
        mock_cursor.fetchall.return_value = [
            {
                "id": 1,
                "student_id": "SV001",
                "fullname": "Nguyen Van A",
                "dob": "2005-02-26",
                "major": "Cloud Computing",
            }
        ]
        mock_conn = MagicMock()
        mock_conn.cursor.return_value.__enter__.return_value = mock_cursor
        mock_get_conn.return_value = mock_conn

        res = self.client.get("/students-db")
        self.assertEqual(res.status_code, 200)
        data = res.get_json()
        self.assertEqual(data.get("source"), "MariaDB (studentdb.students)")
        self.assertEqual(data.get("count"), 1)
        self.assertEqual(len(data.get("students")), 1)

    @patch("app.get_db_connection")
    def test_students_db_post_validation_and_conflict(self, mock_get_conn):
        # 1. Missing student_id
        res_bad1 = self.client.post("/students-db", json={"fullname": "Test", "dob": "2005-01-01", "major": "IT"})
        self.assertEqual(res_bad1.status_code, 400)

        # 2. Invalid date format
        res_bad2 = self.client.post(
            "/students-db",
            json={"student_id": "SV999", "fullname": "Test", "dob": "2005-99-99", "major": "IT"},
        )
        self.assertEqual(res_bad2.status_code, 400)
        self.assertIn("YYYY-MM-DD", res_bad2.get_json().get("error", ""))

        # 3. Duplicate student_id (IntegrityError 1062)
        mock_cursor = MagicMock()
        mock_cursor.execute.side_effect = pymysql.err.IntegrityError(1062, "Duplicate entry for key 'student_id'")
        mock_conn = MagicMock()
        mock_conn.cursor.return_value.__enter__.return_value = mock_cursor
        mock_get_conn.return_value = mock_conn

        res_conflict = self.client.post(
            "/students-db",
            json={"student_id": "SV001", "fullname": "Duplicate", "dob": "2005-01-01", "major": "IT"},
        )
        self.assertEqual(res_conflict.status_code, 409)
        self.assertIn("already exists", res_conflict.get_json().get("error", ""))

        # 4. Valid insert
        mock_cursor.execute.side_effect = None
        mock_cursor.lastrowid = 5
        res_ok = self.client.post(
            "/students-db",
            json={"student_id": "SV005", "fullname": "Hoang Minh E", "dob": "2005-03-19", "major": "Information Systems"},
        )
        self.assertEqual(res_ok.status_code, 201)
        self.assertEqual(res_ok.get_json().get("message"), "Student created successfully")

    @patch("app.get_db_connection")
    def test_students_db_put_and_delete_not_found_and_success(self, mock_get_conn):
        mock_cursor = MagicMock()
        mock_conn = MagicMock()
        mock_conn.cursor.return_value.__enter__.return_value = mock_cursor
        mock_get_conn.return_value = mock_conn

        # 1. PUT 404 when student not found (rowcount = 0, fetchone is None)
        mock_cursor.rowcount = 0
        mock_cursor.fetchone.return_value = None
        res_put_404 = self.client.put("/students-db/SV999", json={"major": "Cloud"})
        self.assertEqual(res_put_404.status_code, 404)

        # 2. PUT 200 when student found (rowcount = 1)
        mock_cursor.rowcount = 1
        mock_cursor.fetchone.return_value = {
            "id": 5,
            "student_id": "SV005",
            "fullname": "Hoang Minh E",
            "dob": "2005-03-19",
            "major": "Cloud Computing",
        }
        res_put_200 = self.client.put("/students-db/SV005", json={"major": "Cloud Computing"})
        self.assertEqual(res_put_200.status_code, 200)
        self.assertEqual(res_put_200.get_json().get("message"), "Student updated successfully")

        # 3. DELETE 404 when student not found
        mock_cursor.rowcount = 0
        res_del_404 = self.client.delete("/students-db/SV999")
        self.assertEqual(res_del_404.status_code, 404)

        # 4. DELETE 200 when student deleted
        mock_cursor.rowcount = 1
        res_del_200 = self.client.delete("/students-db/SV005")
        self.assertEqual(res_del_200.status_code, 200)
        self.assertEqual(res_del_200.get_json().get("message"), "Student deleted successfully")


if __name__ == "__main__":
    unittest.main()

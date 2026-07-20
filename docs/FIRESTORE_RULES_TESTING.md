# Firestore and Storage Rules Test Matrix

Test these cases in the Firebase Emulator Suite before production.

| Case | Expected result |
|---|---|
| Unauthenticated user reads tenant | Denied |
| Active member reads own tenant | Allowed |
| Member reads another tenant | Denied |
| Student reads another student's record | Denied unless explicitly linked/authorized |
| Guardian reads an unlinked student | Denied |
| Teacher views tenant students | Allowed |
| Receptionist creates a student | Allowed |
| Receptionist edits an existing student | Denied unless explicit permission exists |
| Class teacher updates a student | Allowed |
| Non-leadership user archives student | Denied unless `students.archive` is granted |
| Any client hard-deletes a student/event | Denied |
| User changes their own role or tenant list | Denied |
| User switches to a tenant listed in their profile | Allowed |
| User uploads an executable file | Denied |
| User uploads a permitted self-document under 10 MB | Allowed |
| Normal member writes shared tenant files | Denied |
| School leadership writes permitted shared files | Allowed |

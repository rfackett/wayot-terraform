variable "users" {
  default = [
    {
      name = "Ryan"

      email = "ryan@foghornconsulting.com"

      role = "roles/editor"
    },
  ]
}

resource "google_project_iam_binding" "project" {
  count   = "${length(var.users)}"
  project = "${var.project}"
  role    = "${lookup(var.users[count.index], "role")}"

  members = [
    "user:${lookup(var.users[count.index], "email")}",
  ]
}

import { ajax } from "discourse/lib/ajax";
import UserChooser from "discourse/select-kit/components/user-chooser";

export default class ResumeContributorChooser extends UserChooser {
  async search(filter = "") {
    const number = this.studentNumber?.trim();
    if (!number) {
      return [];
    }
    const response = await ajax("/isbf-resume/contributor-users.json", {
      data: { student_number: number },
    });
    if (this.isDestroying || number !== this.studentNumber?.trim()) {
      return [];
    }
    const term = (filter || "").replace(/^@/, "").toLowerCase();
    return (response.users || []).filter((user) =>
      `${user.username} ${user.name || ""}`.toLowerCase().includes(term)
    );
  }
}

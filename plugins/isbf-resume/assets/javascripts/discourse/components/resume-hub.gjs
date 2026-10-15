import ResumeEditor from "./resume-editor";
import ResumeWorkspace from "./resume-workspace";

export default <template>
  <ResumeWorkspace ...attributes @section="generate"><ResumeEditor
    /></ResumeWorkspace>
</template>

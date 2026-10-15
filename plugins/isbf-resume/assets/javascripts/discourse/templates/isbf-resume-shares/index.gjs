import ResumeShareList from "../../components/resume-share-list";

export default <template>
  <ResumeShareList @list="published" @model={{@model}} />
</template>

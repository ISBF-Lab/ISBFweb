import AvatarFrameList from "discourse/plugins/discourse-avatar-frames/admin/components/avatar-frame-list";

export default <template>
  <AvatarFrameList @data={{@controller.model}} />
</template>

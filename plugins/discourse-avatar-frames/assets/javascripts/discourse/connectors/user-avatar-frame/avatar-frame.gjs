import AvatarFrameOverlay from "../../components/avatar-frame-overlay";

export default <template>
  <AvatarFrameOverlay
    @frame={{@outletArgs.user.avatar_frame}}
    @motion={{@outletArgs.motion}}
  />
</template>

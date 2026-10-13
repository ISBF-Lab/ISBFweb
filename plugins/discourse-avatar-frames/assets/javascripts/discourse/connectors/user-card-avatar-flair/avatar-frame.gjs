import AvatarFrameOverlay from "../../components/avatar-frame-overlay";

export default <template>
  {{yield}}
  <AvatarFrameOverlay @frame={{@outletArgs.user.avatar_frame}} />
</template>

import AvatarFrameOverlay from "../../components/avatar-frame-overlay";

export default <template>
  {{yield}}
  <AvatarFrameOverlay @frame={{@outletArgs.post.user_avatar_frame}} />
</template>

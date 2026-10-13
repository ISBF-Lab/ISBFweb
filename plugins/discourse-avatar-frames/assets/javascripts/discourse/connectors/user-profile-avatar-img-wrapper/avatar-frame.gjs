import AvatarFrameOverlay from "../../components/avatar-frame-overlay";

export default <template>
  <span class="avatar-frame__anchor">
    {{yield}}
    <AvatarFrameOverlay @frame={{@outletArgs.user.avatar_frame}} />
  </span>
</template>

# BlockMotion

BlockMotion is a Godot 4 prototype for creating block-style Minecraft animations on Android, Windows, and Linux.

## Current MVP

- 3D block character viewport
- Selectable head, body, arms, and legs
- Pose reset and keyframe capture
- Frame stepping with Left/Right arrow keys
- Project save/load using Godot's `user://` storage
- Offline prompt-based animation generation for wave, walk, jump, and dance

## Run

1. Install Godot 4.2 or newer.
2. Import this folder as a project.
3. Press **Run Project**.

The same project can be exported from Godot's export menu for Android, Windows, and Linux. Mobile touch controls and model import/export are planned follow-up features.

## Create a Minecraft-style animation

1. Launch BlockMotion and select a body part from the **Rig Parts** panel.
2. Use the highlighted part as the active selection. The viewport shows the selected part in yellow.
3. In this MVP, interactive rotation controls are not exposed yet, so the initial keyframes capture the current pose. Pose manipulation controls are planned for the next iteration.
4. Choose a frame with the **Left** and **Right** arrow keys. The current frame is shown in the timeline.
5. Press **Add keyframe (K)** to capture the selected part's rotation at the current frame.
6. Select another body part and repeat the process to build a complete pose.
7. Move to another frame and add new keyframes with different rotations to create movement.
8. Use **Reset pose** whenever you want to return all body parts to their default rotation.
9. Click **Save project** to save the animation data locally, then use **Load** to restore it later.

## Generate from a prompt

1. Enter a prompt in the **Prompt Animation** field.
2. Click **Generate animation** or press **Enter**.
3. Use prompts containing `wave`, `walk`, `run`, `jump`, or `dance`, for example:
   - `Make the character wave`
   - `Create a walking animation`
   - `Make the character jump`
4. The matching motion is converted into keyframes and applied to the block character. Use the arrow keys to preview the generated frames.

The prompt generator currently works offline with these supported animation patterns. Prompts outside these patterns are reported clearly instead of silently producing the wrong animation. The current MVP stores keyframes and poses but does not yet export a Minecraft model or video.

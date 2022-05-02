export default interface Animator {
	LoadAnimation(animation: Animation, name: string): void;

	PlayAniamtion(name: string): void;

	StopAnimation(name: string): void;

	StopAnimations(): void;
}

import Animator from "./Animator";
import CharacterController from "./CharacterController";
import { CharacterState } from "./CharacterState";

export { Animator, CharacterController, CharacterState };

export default class Luanoid {
	public constructor(existingCharacter?: Model);

	private readonly RigParts: Array<BasePart>;
	private readonly RigMotors6Ds: Array<Motor6D>;
	private MoveToPromise: Promise<boolean>;

	public Name: string;
	public MoveDirection: Vector3;
	public LookDirection: Vector3;
	public Health: number;
	public MaxHealth: number;
	public WalkSpeed: number;
	public JumpPower: number;
	public HipHeight: number;
	public MaxSlopeAngle: number;
	public AutoRotate: boolean;
	public Jump: boolean;
	public readonly Animator: Animator;
	public readonly CharacterController: CharacterController;
	public readonly Character: Model;
	public Floor: BasePart;
	public readonly FloorMaterial: EnumItem; // TODO: More specific EnumItem
	public readonly Mover: VectorForce;
	public readonly Aligner: AlignOrientation;
	public readonly RootPart: BasePart;
	public readonly RigChanged: RBXScriptSignal;
	public readonly AccessoryAdded: RBXScriptSignal;
	public readonly AccessoryRemoving: RBXScriptSignal;
	public readonly Died: RBXScriptSignal;
	public readonly FreeFalling: RBXScriptSignal;
	public readonly HealthChanged: RBXScriptSignal;
	public readonly Jumping: RBXScriptSignal;
	public readonly MoveToFinished: RBXScriptSignal;
	public readonly Seated: RBXScriptSignal;
	public readonly StateChanged: RBXScriptSignal;
	public readonly Touched: RBXScriptSignal;
	public readonly Destroying: RBXScriptSignal;

	private _step(dt: number): void;

	public Destroy(): void;

	public SetRig(rig: Model): void;

	public RemoveRig(): void;

	public ApplyDescription(description: HumanoidDescription, rigType?: EnumItem): void;

	public BuildRigFromAttachments(): void;

	public TakeDamage(damage: number): void;

	public Move(moveDirection: Vector3, relativeToCamera?: boolean): void;

	public MoveTo(location?: Vector3, part?: BasePart, targetRadius?: number, timeout?: number): Promise<boolean>;

	public AddAccessory(accessory: Accessory | Model | BasePart, base?: Attachment | BasePart, pivot?: CFrame): void;

	public RemoveAccessory(accessory: Accessory | Model | BasePart): void;

	public GetAccessories(): Array<Accessory | Model | BasePart>;

	public RemoveAccessories(): void;

	public GetNetworkOwner(): Player | undefined;

	public SetNetworkOwner(player?: Player): void;

	public IsNetworkOwner(): boolean;

	public GetState(): CharacterState;

	public ChangeState(newState: CharacterState): void;
}

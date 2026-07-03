"""
Type stubs for the Booster Robotics SDK Python bindings.

Authoritative, hand-maintained type information for the compiled pybind11
extension `booster_robotics_sdk_python`. This file is the source of truth for the
public API surface and is packaged into the wheel by
scripts/cibw_before_build.sh so that downstream `mypy` sees the real symbols.

Keep this in sync with python/binding.cpp when the bindings change. A missing or
stale stub shipped alongside a `py.typed` marker makes mypy treat the extension as
a typed-but-empty module and report `attr-defined` on every symbol at the import
site — so the build refuses to ship `py.typed` without this file.
"""

from typing import Callable, List, Sequence, overload

__version__: str

# ---------------------------------------------------------------------------
# Enums. Each is bound with pybind11's `.export_values()`, so the members are
# also re-exported at module scope (e.g. `booster_robotics_sdk_python.kWalking`).
# ---------------------------------------------------------------------------

class RobotMode:
    kUnknown: RobotMode
    kDamping: RobotMode
    kPrepare: RobotMode
    kWalking: RobotMode
    kCustom: RobotMode
    def __init__(self, value: int) -> None: ...
    @property
    def value(self) -> int: ...
    @property
    def name(self) -> str: ...

kUnknown: RobotMode
kDamping: RobotMode
kPrepare: RobotMode
kWalking: RobotMode
kCustom: RobotMode

class B1JointIndex:
    kHeadYaw: B1JointIndex
    kHeadPitch: B1JointIndex
    kLeftShoulderPitch: B1JointIndex
    kLeftShoulderRoll: B1JointIndex
    kLeftElbowPitch: B1JointIndex
    kLeftElbowYaw: B1JointIndex
    kRightShoulderPitch: B1JointIndex
    kRightShoulderRoll: B1JointIndex
    kRightElbowPitch: B1JointIndex
    kRightElbowYaw: B1JointIndex
    kWaist: B1JointIndex
    kLeftHipPitch: B1JointIndex
    kLeftHipRoll: B1JointIndex
    kLeftHipYaw: B1JointIndex
    kLeftKneePitch: B1JointIndex
    kCrankUpLeft: B1JointIndex
    kCrankDownLeft: B1JointIndex
    kRightHipPitch: B1JointIndex
    kRightHipRoll: B1JointIndex
    kRightHipYaw: B1JointIndex
    kRightKneePitch: B1JointIndex
    kCrankUpRight: B1JointIndex
    kCrankDownRight: B1JointIndex
    def __init__(self, value: int) -> None: ...
    @property
    def value(self) -> int: ...
    @property
    def name(self) -> str: ...

B1JointCnt: int

class B1LocoApiId:
    kChangeMode: B1LocoApiId
    kMove: B1LocoApiId
    kRotateHead: B1LocoApiId
    def __init__(self, value: int) -> None: ...
    @property
    def value(self) -> int: ...
    @property
    def name(self) -> str: ...

class B1HandAction:
    kHandOpen: B1HandAction
    kHandClose: B1HandAction
    def __init__(self, value: int) -> None: ...
    @property
    def value(self) -> int: ...
    @property
    def name(self) -> str: ...

class B1HandIndex:
    kLeftHand: B1HandIndex
    kRightHand: B1HandIndex
    def __init__(self, value: int) -> None: ...
    @property
    def value(self) -> int: ...
    @property
    def name(self) -> str: ...

class GripperControlMode:
    kPosition: GripperControlMode
    kForce: GripperControlMode
    def __init__(self, value: int) -> None: ...
    @property
    def value(self) -> int: ...
    @property
    def name(self) -> str: ...

class Frame:
    kUnknown: Frame
    kBody: Frame
    kHead: Frame
    kLeftHand: Frame
    kRightHand: Frame
    kLeftFoot: Frame
    kRightFoot: Frame
    def __init__(self, value: int) -> None: ...
    @property
    def value(self) -> int: ...
    @property
    def name(self) -> str: ...

class LowCmdType:
    PARALLEL: LowCmdType
    SERIAL: LowCmdType
    def __init__(self, value: int) -> None: ...
    @property
    def value(self) -> int: ...
    @property
    def name(self) -> str: ...

PARALLEL: LowCmdType
SERIAL: LowCmdType

# ---------------------------------------------------------------------------
# Geometry primitives.
# ---------------------------------------------------------------------------

class Position:
    x: float
    y: float
    z: float
    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(self, x: float, y: float, z: float) -> None: ...

class Orientation:
    roll: float
    pitch: float
    yaw: float
    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(self, roll: float, pitch: float, yaw: float) -> None: ...

class Posture:
    position: Position
    orientation: Orientation
    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(self, position: Position, orientation: Orientation) -> None: ...

class Quaternion:
    x: float
    y: float
    z: float
    w: float
    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(self, x: float, y: float, z: float, w: float) -> None: ...

class Transform:
    position: Position
    orientation: Quaternion
    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(self, position: Position, orientation: Quaternion) -> None: ...

class GripperMotionParameter:
    position: int
    force: int
    speed: int
    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(self, position: int, force: int, speed: int) -> None: ...

class DexterousFingerParameter:
    seq: int
    angle: int
    force: int
    speed: int
    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(self, seq: int, angle: int, force: int, speed: int) -> None: ...

# ---------------------------------------------------------------------------
# DDS message types.
# ---------------------------------------------------------------------------

class ImuState:
    rpy: Sequence[float]
    gyro: Sequence[float]
    acc: Sequence[float]
    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(self, other: "ImuState") -> None: ...
    def __eq__(self, other: object) -> bool: ...
    def __ne__(self, other: object) -> bool: ...

class MotorState:
    mode: int
    q: float
    dq: float
    ddq: float
    tau_est: float
    temperature: int
    lost: int
    reserve: Sequence[int]
    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(self, other: "MotorState") -> None: ...
    def __eq__(self, other: object) -> bool: ...
    def __ne__(self, other: object) -> bool: ...

class LowState:
    imu_state: ImuState
    motor_state_parallel: List[MotorState]
    motor_state_serial: List[MotorState]
    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(self, other: "LowState") -> None: ...
    def __eq__(self, other: object) -> bool: ...
    def __ne__(self, other: object) -> bool: ...

class MotorCmd:
    mode: int
    q: float
    dq: float
    tau: float
    kp: float
    kd: float
    weight: float
    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(self, other: "MotorCmd") -> None: ...
    def __eq__(self, other: object) -> bool: ...
    def __ne__(self, other: object) -> bool: ...

class LowCmd:
    cmd_type: LowCmdType
    motor_cmd: List[MotorCmd]
    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(self, other: "LowCmd") -> None: ...
    def __eq__(self, other: object) -> bool: ...
    def __ne__(self, other: object) -> bool: ...

class Odometer:
    x: float
    y: float
    theta: float
    def __init__(self) -> None: ...

class HandReplyParam:
    angle: int
    force: int
    current: int
    error: int
    status: int
    temp: int
    seq: int
    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(self, other: "HandReplyParam") -> None: ...
    def __eq__(self, other: object) -> bool: ...
    def __ne__(self, other: object) -> bool: ...

class HandReplyData:
    hand_index: int
    hand_type: int
    hand_data: List[HandReplyParam]
    @overload
    def __init__(self) -> None: ...
    @overload
    def __init__(self, other: "HandReplyData") -> None: ...
    def __eq__(self, other: object) -> bool: ...
    def __ne__(self, other: object) -> bool: ...

# ---------------------------------------------------------------------------
# Channel factory + pub/sub.
# ---------------------------------------------------------------------------

class ChannelFactory:
    @staticmethod
    def Instance() -> "ChannelFactory": ...
    def Init(self, domain_id: int, network_interface: str = ...) -> None: ...

class B1LowStateSubscriber:
    def __init__(self, handler: Callable[[LowState], None]) -> None: ...
    def InitChannel(self) -> None: ...
    def CloseChannel(self) -> None: ...
    def GetChannelName(self) -> str: ...

class B1LowCmdSubscriber:
    def __init__(self, handler: Callable[[LowCmd], None]) -> None: ...
    def InitChannel(self) -> None: ...
    def CloseChannel(self) -> None: ...
    def GetChannelName(self) -> str: ...

class B1LowHandDataScriber:
    def __init__(self, handler: Callable[[HandReplyData], None]) -> None: ...
    def InitChannel(self) -> None: ...
    def CloseChannel(self) -> None: ...
    def GetChannelName(self) -> str: ...

class B1OdometerStateSubscriber:
    def __init__(self, handler: Callable[[Odometer], None]) -> None: ...
    def InitChannel(self) -> None: ...
    def CloseChannel(self) -> None: ...
    def GetChannelName(self) -> str: ...

class B1LowCmdPublisher:
    def __init__(self) -> None: ...
    def InitChannel(self) -> None: ...
    def Write(self, msg: LowCmd) -> bool: ...
    def CloseChannel(self) -> None: ...
    def GetChannelName(self) -> str: ...

class B1LowStatePublisher:
    def __init__(self) -> None: ...
    def InitChannel(self) -> None: ...
    def Write(self, msg: LowState) -> bool: ...
    def CloseChannel(self) -> None: ...
    def GetChannelName(self) -> str: ...

# ---------------------------------------------------------------------------
# High-level locomotion client.
# ---------------------------------------------------------------------------

class B1LocoClient:
    def __init__(self) -> None: ...
    @overload
    def Init(self) -> int: ...
    @overload
    def Init(self, robot_name: str) -> int: ...
    def SendApiRequest(self, api_id: int, param: str) -> int: ...
    def ChangeMode(self, mode: RobotMode) -> int: ...
    def Move(self, vx: float, vy: float, vyaw: float) -> int: ...
    def RotateHead(self, pitch: float, yaw: float) -> int: ...
    def RotateHeadWithDirection(self, pitch_direction: int, yaw_direction: int) -> int: ...
    def WaveHand(self, action: B1HandAction) -> int: ...
    def Handshake(self, action: B1HandAction) -> int: ...
    def MoveHandEndEffectorWithAux(
        self,
        target_posture: Posture,
        aux_posture: Posture,
        time_millis: int,
        hand_index: B1HandIndex,
    ) -> int: ...
    def MoveHandEndEffector(
        self, target_posture: Posture, time_millis: int, hand_index: B1HandIndex
    ) -> int: ...
    def ControlGripper(
        self,
        motion_param: GripperMotionParameter,
        mode: GripperControlMode,
        hand_index: B1HandIndex,
    ) -> int: ...
    def GetFrameTransform(self, src: Frame, dst: Frame, transform: Transform) -> int: ...
    def SwitchHandEndEffectorControlMode(self, switch_on: bool) -> int: ...
    def ControlDexterousHand(
        self, finger_params: Sequence[DexterousFingerParameter], hand_index: B1HandIndex
    ) -> int: ...
    def GetUp(self) -> int: ...
    def LieDown(self) -> int: ...

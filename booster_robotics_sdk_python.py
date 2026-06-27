"""Top-level alias for the compiled extension module.

Historically (via `make install`) the pybind11 extension was installed directly
into site-packages as the top-level module `booster_robotics_sdk_python`, and all
examples import it that way:

    from booster_robotics_sdk_python import ChannelFactory, B1LocoClient, ...

The wheel packages the compiled extension inside the `booster_robotics_sdk`
package (so auditwheel can bundle the vendored FastDDS libraries alongside it).
This shim preserves the original top-level import: importing
`booster_robotics_sdk_python` transparently resolves to
`booster_robotics_sdk.booster_robotics_sdk_python`, with full module identity
(replacing this shim in sys.modules) so `from booster_robotics_sdk_python import X`
works exactly as before.
"""

import sys as _sys

from booster_robotics_sdk import booster_robotics_sdk_python as _ext

# Replace this shim with the real extension module so attribute access,
# `from ... import name`, and module identity all behave identically to the
# historical top-level module.
_sys.modules[__name__] = _ext

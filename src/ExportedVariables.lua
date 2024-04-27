--@class ExportedVariables

shipName = ""
updateSettings = false --export: Use these settings
altHoldPreset1 = 132000.845  --export: Altitude Hold Preset 1
altHoldPreset2 = 1005 --export: Altitude Hold Preset 2
altHoldPreset3 = 50 --export: Altitude Hold Preset 3
altHoldPreset4 = 2 --export: Altitude Hold Preset 4
deviationThreshold = 0.5 --export: Deviation tolerace in m
inertialDampening = true --export: Start with inertial dampening on/off
followGravity = true --export: Start with gravity follow on/off
minRotationSpeed = 0.01 --export: Minimum speed rotation scales from
maxRotationSpeed = 5 --export: Maximum speed rotation scales to
rotationStep = 0.03 --export: Depermines how quickly rotation scales up
verticalSpeedLimitAtmo = 1100 --export: Vertical speed limit in atmosphere
verticalSpeedLimitSpace = 4000 --export: Vertical limit in space
approachSpeed = 200 --export: Max final approach speed
autoShutdown = true --export: Auto shutoff on RTB landing
breadCrumbDist = 1000 --export: Distance of vector breadcrumbs for elevator control
ContainerOptimization = 0 --export: Container ContainerOptimization
FuelTankOptimization = 0 --export: Fuel Tank FuelTankOptimization
fuelTankHandlingAtmo = 0 --export: Fuel Tank Handling Atmo
fuelTankHandlingSpace = 0 --export: Fuel Tank Handling Space

primaryColor = "b80000" --export: Primary color of HUD
secondaryColor = "e30000" --export: Secondary color of HUD
textShadow = "e81313" --export: Color of text shadow for speedometer
ARCrosshair = "ebbb0c" --export: Color of the AR crosshair
fuelFontSize = 1.8 --export: Fuel Gauge Font Size

showDockingWidget = true --export: Show Docking Widget
dockingMode = 1 --export: Set docking mode (1:Manual, 2:Automatic, 3:Semi-Automatic)
setBaseOnStart = false --export: Set RTB location on start
useGEAS = false --export:
GEAS_Alt = 10 --export:
activateFFonStart = false --export: Activate force fields on start (connected to button)
local pocket = false --export: Pocket ship?
mouseSensitivity = 1 --export: Enter your mouse sensativity setting
enableARReticle = false --export: Enable AR reticle

--charMovement = true --export: Enable/Disable Character Movement
import QtQuick
import Quickshell.Services.UPower
import qs.components
import qs.services
import qs.utils

MaterialIcon {
    required property color colour

    animate: true
    text: {
        if (!UPower.displayDevice.isLaptopBattery) {
            if (PowerProfiles.profile === PowerProfile.PowerSaver)
                return "energy_savings_leaf";
            if (PowerProfiles.profile === PowerProfile.Performance)
                return "rocket_launch";
            return "balance";
        }
        return Icons.getBatteryIcon(UPower.displayDevice.percentage, [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state));
    }
    color: {
        if (!UPower.displayDevice.isLaptopBattery) {
            if (PowerProfiles.profile === PowerProfile.PowerSaver)
                return Colours.palette.m3success;
            if (PowerProfiles.profile === PowerProfile.Performance)
                return Colours.palette.m3tertiary;
            return colour;
        }
        if ([UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state))
            return Colours.palette.m3success;
        if (!UPower.onBattery)
            return colour;
        if (UPower.displayDevice.percentage <= 0.2)
            return Colours.palette.m3error;
        if (UPower.displayDevice.percentage <= 0.35)
            return Colours.palette.m3tertiary;
        return colour;
    }
    fill: 1
}

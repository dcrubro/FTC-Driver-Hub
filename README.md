![FTC Driver Hub](./Assets/FTCDriverHubFULL.png)

## What is it?

This project is an attempt to port the REV Driver Hub to iOS.

Currently the REV Driver Hub is only written for Android (Natively by REV) and for Desktop (FTC Tui by [FIRST Slovenia](https://firstslo.si/)). I decided, part for functionality and part as a learning challenge, to port the Driver Hub to iOS as well (and coincidentally also to iPadOS).

It only uses native Swift code and no outside code/libraries, except for those provided by Apple themselves.

## Project Status
Packets are being exchanged pretty reliably now, with inital connection, heartbeat, command and telemetry logic in place. Work is currently underway on making the gamepad packets work, and actually enable the app to control the robot (Control Hub).

## How to Build
Due to security reasons, the source code is provided with minimal Xcode project files. This is to avoid leaking any potential private info and provisioning keys (since that would be really bad).

I don't exactly know how to build the project from the cloned repo yet, but you'd probably need to remake the Xcode project from scratch (good luck).

I'll update this at some point with actual build instructions.

## Misc. Info
The Xcode project is targeting iOS 17.6, although it should be able to run on older versions of iOS.

Hopefully one day when I actually purchase a developer license from Apple, I can get this on the App Store. In the meantime, you can sideload it.

Huge thanks to the REVersing project by [FIRST Slovenia](https://firstslo.si/) for supplying the base description of the protocol (it probably saved me days of staring at Wireshark).

## Legal

Copyright (C) 2025 Jonas Korene Novak

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.

DcruBro is the online pseudonym of Jonas Korene Novak. Both refer to the same individual and may be used interchangeably for copyright attribution purposes.

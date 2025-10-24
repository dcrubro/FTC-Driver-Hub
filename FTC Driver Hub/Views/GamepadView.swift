//
//  GamepadView.swift
//  FTC Driver Hub
//
//  Created by dcrubro on 11. 10. 25.
//

import SwiftUI

struct GamepadView: View {
    @EnvironmentObject var controller: FTCController

    @State private var leftStick = CGPoint.zero
    @State private var rightStick = CGPoint.zero
    @State private var pressedButtons: Set<String> = []
    @State private var leftTrigger: Float = 0
    @State private var rightTrigger: Float = 0
    @State private var lastSend = Date()

    private let maxOffset: CGFloat = 40

    // MARK: - Main Body
    var body: some View {
        GeometryReader { geo in
            content(for: geo)
                .onReceive(NotificationCenter.default.publisher(for: .joystickReleased)) { _ in
                    // Send explicit zeroed packet (even if @State not yet updated)
                    controller.updateGamepad(
                        leftX: 0,
                        leftY: 0,
                        rightX: 0,
                        rightY: 0,
                        leftTrigger: 0,
                        rightTrigger: 0,
                        buttons: []
                    )
                }
        }
    }
}

extension GamepadView {

    // MARK: - Top-Level Layout
    @ViewBuilder
    private func content(for geo: GeometryProxy) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()
            controllerLayout(in: geo)
        }
        .onChange(of: leftStick) { _ in sendGamepad() }
        .onChange(of: rightStick) { _ in sendGamepad() }
        .onChange(of: pressedButtons) { _ in sendGamepad() }
        .onChange(of: leftTrigger) { _ in sendGamepad() }
        .onChange(of: rightTrigger) { _ in sendGamepad() }
    }

    // MARK: - Controller halves container
    @ViewBuilder
    private func controllerLayout(in geo: GeometryProxy) -> some View {
        let safe = geo.safeAreaInsets
        let safeWidth = geo.size.width - safe.leading - safe.trailing
        let safeHeight = geo.size.height - safe.top - safe.bottom
        let halfWidth = safeWidth / 2

        HStack(spacing: safeWidth * 0.05) {
            leftController(width: halfWidth, height: safeHeight)
            rightController(width: halfWidth, height: safeHeight)
        }
        .padding(.horizontal, safeWidth * 0.03)
    }

    // MARK: - Left controller layout
    @ViewBuilder
    private func leftController(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            // Joystick + triggers moved up
            VStack(spacing: max(12, height * 0.035)) {
                HStack(spacing: 18) {
                    TriggerButton(label: "L1", isPressed: pressedButtons.contains("l1")) {
                        press("l1", true)
                    } onRelease: { press("l1", false) }

                    TriggerButton(label: "L2", isPressed: leftTrigger > 0.1) {
                        leftTrigger = 1
                    } onRelease: { leftTrigger = 0 }
                }

                JoystickView(offset: $leftStick, color: .blue)
                    .frame(width: min(width * 0.33, 170),
                           height: min(width * 0.33, 170))
            }
            .offset(y: -height * 0.12) // ⬆️ push higher on screen

            // D-pad raised and pushed further left
            VStack {
                Spacer()
                DPadView(pressedButtons: $pressedButtons)
                    .frame(width: min(width * 0.3, 150),
                           height: min(width * 0.3, 150))
                    .offset(x: -width * 0.32, y: height * 0.05)
            }
        }
    }

    // MARK: - Right controller layout
    @ViewBuilder
    private func rightController(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            // Joystick + triggers moved up
            VStack(spacing: max(12, height * 0.035)) {
                HStack(spacing: 18) {
                    TriggerButton(label: "R1", isPressed: pressedButtons.contains("r1")) {
                        press("r1", true)
                    } onRelease: { press("r1", false) }

                    TriggerButton(label: "R2", isPressed: rightTrigger > 0.1) {
                        rightTrigger = 1
                    } onRelease: { rightTrigger = 0 }
                }

                JoystickView(offset: $rightStick, color: .red)
                    .frame(width: min(width * 0.33, 170),
                           height: min(width * 0.33, 170))
            }
            .offset(y: -height * 0.12) // ⬆️ push higher

            // Shape buttons raised and pushed right
            VStack {
                Spacer()
                ShapeButtonsView(pressedButtons: $pressedButtons)
                    .frame(width: min(width * 0.35, 170),
                           height: min(width * 0.35, 170))
                    .offset(x: width * 0.32, y: height * 0.05)
            }
        }
    }

    // MARK: - Gamepad bridge and helpers
    private func sendGamepad() {
        guard Date().timeIntervalSince(lastSend) > 0.04 else { return } // 25Hz
        lastSend = Date()

        controller.updateGamepad(
            leftX: leftStick.x / maxOffset,
            leftY: -leftStick.y / maxOffset,
            rightX: rightStick.x / maxOffset,
            rightY: -rightStick.y / maxOffset,
            leftTrigger: Double(leftTrigger),
            rightTrigger: Double(rightTrigger),
            buttons: pressedButtons
        )
    }

    private func press(_ id: String, _ down: Bool) {
        if down { pressedButtons.insert(id) } else { pressedButtons.remove(id) }
    }
}

// MARK: - Each side has its own frame and spacing logic
struct ControllerSide<Content: View>: View {
    var width: CGFloat
    var height: CGFloat
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            Color.clear
            content()
        }
        .frame(width: width * 0.9, height: height, alignment: .center)
    }
}

// MARK: - Joystick
struct JoystickView: View {
    @Binding var offset: CGPoint
    var color: Color
    private let maxOffset: CGFloat = 40

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 130, height: 130)

            Circle()
                .fill(color)
                .frame(width: 80, height: 80)
                .offset(x: offset.x, y: offset.y)
                .shadow(color: color.opacity(0.5), radius: 8)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let dx = min(max(value.translation.width, -maxOffset), maxOffset)
                            let dy = min(max(value.translation.height, -maxOffset), maxOffset)
                            offset = CGPoint(x: dx, y: dy)
                        }
                        .onEnded { _ in
                            // Immediately zero and notify parent of change
                            offset = .zero
                            
                            // Explicitly send neutral state right now
                            NotificationCenter.default.post(name: .joystickReleased, object: nil)
                            
                            // Animate back visually
                            withAnimation(.spring()) { offset = .zero }
                        }
                )
        }
    }
}

extension Notification.Name {
    static let joystickReleased = Notification.Name("joystickReleased")
}

// MARK: - Shape Buttons (△ ○ × □)
struct ShapeButtonsView: View {
    @Binding var pressedButtons: Set<String>

    var body: some View {
        VStack(spacing: 20) {
            GamepadButton(label: "△", id: "triangle", color: .green, pressedButtons: $pressedButtons)
            HStack(spacing: 20) {
                GamepadButton(label: "□", id: "square", color: .blue, pressedButtons: $pressedButtons)
                GamepadButton(label: "○", id: "circle", color: .red, pressedButtons: $pressedButtons)
            }
            GamepadButton(label: "×", id: "cross", color: .purple, pressedButtons: $pressedButtons)
        }
    }
}

// MARK: - D-Pad
struct DPadView: View {
    @Binding var pressedButtons: Set<String>

    var body: some View {
        VStack(spacing: 10) {
            GamepadButton(label: "▲", id: "dpad_up", color: .gray, pressedButtons: $pressedButtons)
            HStack(spacing: 10) {
                GamepadButton(label: "◀︎", id: "dpad_left", color: .gray, pressedButtons: $pressedButtons)
                GamepadButton(label: "▶︎", id: "dpad_right", color: .gray, pressedButtons: $pressedButtons)
            }
            GamepadButton(label: "▼", id: "dpad_down", color: .gray, pressedButtons: $pressedButtons)
        }
    }
}

// MARK: - Trigger Button
struct TriggerButton: View {
    var label: String
    var isPressed: Bool
    var onPress: () -> Void
    var onRelease: () -> Void

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(isPressed ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
            .frame(width: 70, height: 40)
            .overlay(Text(label).font(.headline).foregroundColor(.white))
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
            .animation(.easeOut(duration: 0.1), value: isPressed)
    }
}

// MARK: - General Button
struct GamepadButton: View {
    var label: String
    var id: String
    var color: Color
    @Binding var pressedButtons: Set<String>

    var body: some View {
        let pressed = pressedButtons.contains(id)

        Circle()
            .fill(pressed ? color : color.opacity(0.4))
            .frame(width: 60, height: 60)
            .overlay(Text(label).font(.headline).foregroundColor(.white))
            .scaleEffect(pressed ? 0.9 : 1.0)
            .shadow(color: pressed ? color.opacity(0.6) : .clear, radius: 6)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in pressedButtons.insert(id) }
                    .onEnded { _ in pressedButtons.remove(id) }
            )
            .animation(.easeOut(duration: 0.1), value: pressed)
    }
}

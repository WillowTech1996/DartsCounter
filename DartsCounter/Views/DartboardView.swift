import SwiftUI

// MARK: - Dartboard View
struct DartboardView: View {
    let dartHits: [DartHit]
    let size: CGFloat

    var body: some View {
        ZStack {
            // Draw dartboard segments
            DartboardSegments(size: size)

            // Draw dart hits
            ForEach(Array(dartHits.enumerated()), id: \.element.id) { index, hit in
                DartMarker(hit: hit, size: size, dartNumber: index + 1)
            }
        }
    }
}

// MARK: - Dartboard Segments
struct DartboardSegments: View {
    let size: CGFloat

    // Standard dartboard number arrangement (clockwise from top)
    let numbers = [20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5]

    var body: some View {
        ZStack {
            // Draw 20 segments extending all the way to center
            ForEach(0..<20) { index in
                let color = index % 2 == 0 ? Color.black : Color.white.opacity(0.9)
                let alternateColor = index % 2 == 0 ? Color.red : Color.green

                // Inner singles area (from center to triples)
                SegmentWedge(
                    startAngle: startAngle(for: index),
                    endAngle: endAngle(for: index),
                    innerRadius: size * 0.08,
                    outerRadius: size * 0.32
                )
                .fill(color)

                // Triples ring
                SegmentWedge(
                    startAngle: startAngle(for: index),
                    endAngle: endAngle(for: index),
                    innerRadius: size * 0.32,
                    outerRadius: size * 0.35
                )
                .fill(alternateColor)

                // Outer singles area
                SegmentWedge(
                    startAngle: startAngle(for: index),
                    endAngle: endAngle(for: index),
                    innerRadius: size * 0.35,
                    outerRadius: size * 0.47
                )
                .fill(color)

                // Doubles ring
                SegmentWedge(
                    startAngle: startAngle(for: index),
                    endAngle: endAngle(for: index),
                    innerRadius: size * 0.47,
                    outerRadius: size * 0.50
                )
                .fill(alternateColor)

                // Number labels
                NumberLabel(
                    number: numbers[index],
                    angle: (startAngle(for: index) + endAngle(for: index)) / 2,
                    radius: size * 0.56,
                    size: size
                )
            }

            // Outer bull ring (25) - green ring
            Circle()
                .fill(Color.green)
                .frame(width: size * 0.16, height: size * 0.16)

            // Bullseye (50) - red center
            Circle()
                .fill(Color.red)
                .frame(width: size * 0.08, height: size * 0.08)
        }
    }

    func startAngle(for index: Int) -> Angle {
        // Start from top and rotate clockwise
        // Each segment is 18 degrees (360/20)
        // Offset by -9 degrees so 20 is at top
        return Angle.degrees(Double(index) * 18 - 99)
    }

    func endAngle(for index: Int) -> Angle {
        return Angle.degrees(Double(index + 1) * 18 - 99)
    }
}

// MARK: - Segment Wedge Shape
struct SegmentWedge: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let innerRadius: CGFloat
    let outerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)

        var path = Path()

        // Move to inner arc start
        let innerStart = pointOnCircle(center: center, radius: innerRadius, angle: startAngle)
        path.move(to: innerStart)

        // Draw outer arc
        let outerStart = pointOnCircle(center: center, radius: outerRadius, angle: startAngle)
        path.addLine(to: outerStart)
        path.addArc(center: center, radius: outerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)

        // Draw back to inner arc
        let innerEnd = pointOnCircle(center: center, radius: innerRadius, angle: endAngle)
        path.addLine(to: innerEnd)
        path.addArc(center: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)

        return path
    }

    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        let x = center.x + radius * CGFloat(Darwin.cos(angle.radians))
        let y = center.y + radius * CGFloat(Darwin.sin(angle.radians))
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Number Label
struct NumberLabel: View {
    let number: Int
    let angle: Angle
    let radius: CGFloat
    let size: CGFloat

    var body: some View {
        let x = Darwin.cos(angle.radians) * radius
        let y = Darwin.sin(angle.radians) * radius

        Text("\(number)")
            .font(.system(size: size * 0.06, weight: .bold))
            .foregroundColor(.white)
            .offset(x: x, y: y)
    }
}

// MARK: - Dart Marker
struct DartMarker: View {
    let hit: DartHit
    let size: CGFloat
    let dartNumber: Int

    // Standard dartboard number arrangement (clockwise from top)
    let numbers = [20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5]

    var body: some View {
        let position = calculatePosition()

        ZStack {
            // Dart circle
            Circle()
                .fill(dartColor)
                .frame(width: size * 0.06, height: size * 0.06)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )

            // Dart number
            Text("\(dartNumber)")
                .font(.system(size: size * 0.04, weight: .bold))
                .foregroundColor(.white)
        }
        .offset(x: position.x, y: position.y)
        .transition(.scale.combined(with: .opacity))
    }

    var dartColor: Color {
        switch dartNumber {
        case 1: return .yellow
        case 2: return .cyan
        case 3: return .purple
        default: return .orange
        }
    }

    func calculatePosition() -> CGPoint {
        // Handle bullseye and 25
        if hit.segment == 50 {
            // Bullseye - random position in center
            let angle = Double.random(in: 0...(2 * .pi))
            let radius = size * Double.random(in: 0.01...0.03)
            return CGPoint(x: Darwin.cos(angle) * radius, y: Darwin.sin(angle) * radius)
        }

        if hit.segment == 25 {
            // Outer bull - random position in green ring
            let angle = Double.random(in: 0...(2 * .pi))
            let radius = size * Double.random(in: 0.05...0.10)
            return CGPoint(x: Darwin.cos(angle) * radius, y: Darwin.sin(angle) * radius)
        }

        // Handle miss
        if hit.multiplier == 0 {
            // Miss - outside the board
            let angle = Double.random(in: 0...(2 * .pi))
            let radius = size * Double.random(in: 0.52...0.60)
            return CGPoint(x: Darwin.cos(angle) * radius, y: Darwin.sin(angle) * radius)
        }

        // Find segment index for the number
        guard let segmentIndex = numbers.firstIndex(of: hit.segment) else {
            return CGPoint.zero
        }

        // Calculate angle for this segment (with some randomness)
        let baseAngle = Double(segmentIndex) * 18 - 90 // -90 to align with top
        let angleVariation = Double.random(in: -7...7) // Variation within segment
        let angle = (baseAngle + angleVariation) * .pi / 180

        // Calculate radius based on multiplier
        var minRadius: CGFloat = 0
        var maxRadius: CGFloat = 0

        switch hit.multiplier {
        case 1: // Single
            // Inner singles or outer singles (randomly choose)
            if Bool.random() {
                minRadius = size * 0.10
                maxRadius = size * 0.30
            } else {
                minRadius = size * 0.36
                maxRadius = size * 0.46
            }
        case 2: // Double
            minRadius = size * 0.47
            maxRadius = size * 0.50
        case 3: // Triple
            minRadius = size * 0.32
            maxRadius = size * 0.35
        default:
            minRadius = size * 0.10
            maxRadius = size * 0.30
        }

        let radius = CGFloat.random(in: minRadius...maxRadius)

        return CGPoint(
            x: Darwin.cos(angle) * radius,
            y: Darwin.sin(angle) * radius
        )
    }
}

// MARK: - Preview
#Preview {
    VStack {
        DartboardView(
            dartHits: [
                DartHit(score: 60, segment: 20, multiplier: 3),
                DartHit(score: 60, segment: 20, multiplier: 3),
                DartHit(score: 50, segment: 50, multiplier: 1)
            ],
            size: 300
        )
    }
    .frame(width: 400, height: 400)
    .background(Color(red: 0.1, green: 0.12, blue: 0.15))
}

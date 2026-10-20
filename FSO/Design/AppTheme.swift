import SwiftUI

enum AppColorTheme: String, CaseIterable, Identifiable {
    case graphite = "Graphite"
    case ocean = "Ocean"
    case forest = "Forest"
    case rose = "Rose"
    case violet = "Violet"
    case indigo = "Indigo"
    case teal = "Teal"
    case mint = "Mint"
    case amber = "Amber"
    case sunset = "Sunset"
    case crimson = "Crimson"
    case slate = "Slate"
    case midnight = "Midnight"
    case ice = "Ice"
    case coral = "Coral"
    case lavender = "Lavender"
    case emerald = "Emerald"
    case gold = "Gold"
    case plum = "Plum"
    case sky = "Sky"
    case bronze = "Bronze"
    case peach = "Peach"
    case ruby = "Ruby"
    case magenta = "Magenta"
    case fuchsia = "Fuchsia"
    case orchid = "Orchid"
    case grape = "Grape"
    case cobalt = "Cobalt"
    case sapphire = "Sapphire"
    case aqua = "Aqua"
    case lagoon = "Lagoon"
    case jade = "Jade"
    case lime = "Lime"
    case olive = "Olive"
    case moss = "Moss"
    case lemon = "Lemon"
    case tangerine = "Tangerine"
    case pumpkin = "Pumpkin"
    case espresso = "Espresso"
    case mocha = "Mocha"
    case pearl = "Pearl"
    case cyber = "Cyber"
    case ultraviolet = "Ultraviolet"
    case aurora = "Aurora"
    case borealis = "Borealis"
    case nebula = "Nebula"
    case prism = "Prism"
    case opal = "Opal"
    case solstice = "Solstice"
    case ion = "Ion"
    case dream = "Dream"
    case polar = "Polar"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .graphite: return "circle.lefthalf.filled"
        case .ocean: return "water.waves"
        case .forest: return "leaf.fill"
        case .rose: return "camera.macro"
        case .violet: return "sparkles"
        case .indigo: return "moon.stars.fill"
        case .teal: return "drop.fill"
        case .mint: return "leaf.circle.fill"
        case .amber: return "sun.max.fill"
        case .sunset: return "sunset.fill"
        case .crimson: return "flame.fill"
        case .slate: return "square.stack.3d.up.fill"
        case .midnight: return "moon.fill"
        case .ice: return "snowflake"
        case .coral: return "heart.circle.fill"
        case .lavender: return "wand.and.stars"
        case .emerald: return "diamond.fill"
        case .gold: return "crown.fill"
        case .plum: return "circle.grid.cross.fill"
        case .sky: return "cloud.sun.fill"
        case .bronze: return "shield.fill"
        case .peach: return "sun.haze.fill"
        case .ruby: return "suit.diamond.fill"
        case .magenta: return "paintpalette.fill"
        case .fuchsia: return "camera.filters"
        case .orchid: return "sparkle.magnifyingglass"
        case .grape: return "circle.hexagongrid.fill"
        case .cobalt: return "circle.grid.2x2.fill"
        case .sapphire: return "seal.fill"
        case .aqua: return "drop.circle.fill"
        case .lagoon: return "water.waves.and.arrow.down"
        case .jade: return "hexagon.fill"
        case .lime: return "bolt.fill"
        case .olive: return "leaf.arrow.circlepath"
        case .moss: return "tree.fill"
        case .lemon: return "sun.min.fill"
        case .tangerine: return "circle.fill"
        case .pumpkin: return "sun.max.trianglebadge.exclamationmark"
        case .espresso: return "cup.and.saucer.fill"
        case .mocha: return "mug.fill"
        case .pearl: return "smallcircle.filled.circle.fill"
        case .cyber: return "cpu.fill"
        case .ultraviolet: return "rays"
        case .aurora: return "waveform.path.ecg"
        case .borealis: return "wave.3.forward"
        case .nebula: return "sparkles"
        case .prism: return "triangle.fill"
        case .opal: return "circle.dotted"
        case .solstice: return "sun.max.circle.fill"
        case .ion: return "atom"
        case .dream: return "cloud.moon.fill"
        case .polar: return "snowflake.circle.fill"
        }
    }

    var colors: ThemeColors {
        switch self {
        case .graphite:
            return ThemeColors(
                black: Color(red: 0.05, green: 0.05, blue: 0.06),
                darkGray: Color(red: 0.10, green: 0.10, blue: 0.11),
                midGray: Color(red: 0.16, green: 0.16, blue: 0.17),
                lightGray: Color(red: 0.24, green: 0.24, blue: 0.26),
                accent: Color(red: 0.72, green: 0.72, blue: 0.75),
                accentSecondary: Color(red: 0.42, green: 0.42, blue: 0.45),
                glow: Color(red: 0.88, green: 0.88, blue: 0.90)
            )
        case .ocean:
            return ThemeColors(
                black: Color(red: 0.03, green: 0.08, blue: 0.10),
                darkGray: Color(red: 0.06, green: 0.15, blue: 0.18),
                midGray: Color(red: 0.10, green: 0.22, blue: 0.26),
                lightGray: Color(red: 0.16, green: 0.35, blue: 0.40),
                accent: Color(red: 0.50, green: 0.86, blue: 0.92),
                accentSecondary: Color(red: 0.20, green: 0.55, blue: 0.62),
                glow: Color(red: 0.68, green: 0.96, blue: 1.00)
            )
        case .forest:
            return ThemeColors(
                black: Color(red: 0.04, green: 0.08, blue: 0.05),
                darkGray: Color(red: 0.08, green: 0.14, blue: 0.09),
                midGray: Color(red: 0.13, green: 0.22, blue: 0.15),
                lightGray: Color(red: 0.22, green: 0.34, blue: 0.24),
                accent: Color(red: 0.62, green: 0.84, blue: 0.52),
                accentSecondary: Color(red: 0.36, green: 0.57, blue: 0.33),
                glow: Color(red: 0.78, green: 0.94, blue: 0.68)
            )
        case .rose:
            return ThemeColors(
                black: Color(red: 0.10, green: 0.05, blue: 0.07),
                darkGray: Color(red: 0.17, green: 0.09, blue: 0.12),
                midGray: Color(red: 0.25, green: 0.13, blue: 0.17),
                lightGray: Color(red: 0.39, green: 0.22, blue: 0.28),
                accent: Color(red: 0.96, green: 0.63, blue: 0.72),
                accentSecondary: Color(red: 0.68, green: 0.34, blue: 0.45),
                glow: Color(red: 1.00, green: 0.78, blue: 0.84)
            )
        case .violet:
            return ThemeColors(
                black: Color(red: 0.06, green: 0.04, blue: 0.10),
                darkGray: Color(red: 0.11, green: 0.08, blue: 0.18),
                midGray: Color(red: 0.18, green: 0.13, blue: 0.27),
                lightGray: Color(red: 0.30, green: 0.22, blue: 0.42),
                accent: Color(red: 0.78, green: 0.62, blue: 0.96),
                accentSecondary: Color(red: 0.50, green: 0.34, blue: 0.76),
                glow: Color(red: 0.90, green: 0.78, blue: 1.00)
            )
        case .indigo:
            return ThemeColors(
                black: Color(red: 0.04, green: 0.05, blue: 0.12),
                darkGray: Color(red: 0.08, green: 0.10, blue: 0.22),
                midGray: Color(red: 0.13, green: 0.16, blue: 0.33),
                lightGray: Color(red: 0.22, green: 0.27, blue: 0.50),
                accent: Color(red: 0.58, green: 0.68, blue: 1.00),
                accentSecondary: Color(red: 0.34, green: 0.42, blue: 0.78),
                glow: Color(red: 0.74, green: 0.82, blue: 1.00)
            )
        case .teal:
            return ThemeColors(
                black: Color(red: 0.03, green: 0.09, blue: 0.09),
                darkGray: Color(red: 0.06, green: 0.16, blue: 0.16),
                midGray: Color(red: 0.10, green: 0.25, blue: 0.24),
                lightGray: Color(red: 0.16, green: 0.40, blue: 0.38),
                accent: Color(red: 0.45, green: 0.94, blue: 0.85),
                accentSecondary: Color(red: 0.22, green: 0.62, blue: 0.57),
                glow: Color(red: 0.62, green: 1.00, blue: 0.94)
            )
        case .mint:
            return ThemeColors(
                black: Color(red: 0.04, green: 0.09, blue: 0.07),
                darkGray: Color(red: 0.07, green: 0.16, blue: 0.12),
                midGray: Color(red: 0.11, green: 0.25, blue: 0.19),
                lightGray: Color(red: 0.18, green: 0.39, blue: 0.30),
                accent: Color(red: 0.59, green: 0.95, blue: 0.74),
                accentSecondary: Color(red: 0.32, green: 0.63, blue: 0.46),
                glow: Color(red: 0.76, green: 1.00, blue: 0.86)
            )
        case .amber:
            return ThemeColors(
                black: Color(red: 0.10, green: 0.07, blue: 0.03),
                darkGray: Color(red: 0.17, green: 0.12, blue: 0.05),
                midGray: Color(red: 0.27, green: 0.19, blue: 0.08),
                lightGray: Color(red: 0.42, green: 0.31, blue: 0.14),
                accent: Color(red: 1.00, green: 0.78, blue: 0.36),
                accentSecondary: Color(red: 0.74, green: 0.49, blue: 0.18),
                glow: Color(red: 1.00, green: 0.90, blue: 0.58)
            )
        case .sunset:
            return ThemeColors(
                black: Color(red: 0.11, green: 0.05, blue: 0.04),
                darkGray: Color(red: 0.19, green: 0.09, blue: 0.07),
                midGray: Color(red: 0.30, green: 0.14, blue: 0.11),
                lightGray: Color(red: 0.47, green: 0.24, blue: 0.18),
                accent: Color(red: 1.00, green: 0.56, blue: 0.38),
                accentSecondary: Color(red: 0.79, green: 0.32, blue: 0.24),
                glow: Color(red: 1.00, green: 0.72, blue: 0.52)
            )
        case .crimson:
            return ThemeColors(
                black: Color(red: 0.10, green: 0.03, blue: 0.04),
                darkGray: Color(red: 0.17, green: 0.06, blue: 0.08),
                midGray: Color(red: 0.27, green: 0.10, blue: 0.13),
                lightGray: Color(red: 0.43, green: 0.17, blue: 0.21),
                accent: Color(red: 0.98, green: 0.39, blue: 0.47),
                accentSecondary: Color(red: 0.72, green: 0.18, blue: 0.27),
                glow: Color(red: 1.00, green: 0.58, blue: 0.64)
            )
        case .slate:
            return ThemeColors(
                black: Color(red: 0.05, green: 0.06, blue: 0.07),
                darkGray: Color(red: 0.10, green: 0.12, blue: 0.14),
                midGray: Color(red: 0.16, green: 0.19, blue: 0.22),
                lightGray: Color(red: 0.26, green: 0.30, blue: 0.35),
                accent: Color(red: 0.70, green: 0.80, blue: 0.88),
                accentSecondary: Color(red: 0.43, green: 0.52, blue: 0.60),
                glow: Color(red: 0.84, green: 0.90, blue: 0.96)
            )
        case .midnight:
            return ThemeColors(
                black: Color(red: 0.02, green: 0.03, blue: 0.08),
                darkGray: Color(red: 0.05, green: 0.07, blue: 0.16),
                midGray: Color(red: 0.09, green: 0.12, blue: 0.25),
                lightGray: Color(red: 0.16, green: 0.21, blue: 0.38),
                accent: Color(red: 0.48, green: 0.76, blue: 1.00),
                accentSecondary: Color(red: 0.24, green: 0.42, blue: 0.74),
                glow: Color(red: 0.66, green: 0.86, blue: 1.00)
            )
        case .ice:
            return ThemeColors(
                black: Color(red: 0.04, green: 0.07, blue: 0.09),
                darkGray: Color(red: 0.08, green: 0.13, blue: 0.16),
                midGray: Color(red: 0.13, green: 0.21, blue: 0.25),
                lightGray: Color(red: 0.22, green: 0.34, blue: 0.40),
                accent: Color(red: 0.73, green: 0.93, blue: 1.00),
                accentSecondary: Color(red: 0.43, green: 0.68, blue: 0.78),
                glow: Color(red: 0.88, green: 0.98, blue: 1.00)
            )
        case .coral:
            return ThemeColors(
                black: Color(red: 0.11, green: 0.05, blue: 0.05),
                darkGray: Color(red: 0.19, green: 0.09, blue: 0.08),
                midGray: Color(red: 0.29, green: 0.14, blue: 0.12),
                lightGray: Color(red: 0.45, green: 0.24, blue: 0.20),
                accent: Color(red: 1.00, green: 0.52, blue: 0.44),
                accentSecondary: Color(red: 0.78, green: 0.30, blue: 0.28),
                glow: Color(red: 1.00, green: 0.70, blue: 0.62)
            )
        case .lavender:
            return ThemeColors(
                black: Color(red: 0.07, green: 0.05, blue: 0.11),
                darkGray: Color(red: 0.13, green: 0.10, blue: 0.19),
                midGray: Color(red: 0.21, green: 0.16, blue: 0.29),
                lightGray: Color(red: 0.34, green: 0.26, blue: 0.44),
                accent: Color(red: 0.82, green: 0.68, blue: 0.98),
                accentSecondary: Color(red: 0.56, green: 0.40, blue: 0.78),
                glow: Color(red: 0.92, green: 0.82, blue: 1.00)
            )
        case .emerald:
            return ThemeColors(
                black: Color(red: 0.03, green: 0.08, blue: 0.06),
                darkGray: Color(red: 0.06, green: 0.15, blue: 0.11),
                midGray: Color(red: 0.10, green: 0.24, blue: 0.17),
                lightGray: Color(red: 0.16, green: 0.38, blue: 0.28),
                accent: Color(red: 0.34, green: 0.92, blue: 0.68),
                accentSecondary: Color(red: 0.18, green: 0.62, blue: 0.44),
                glow: Color(red: 0.56, green: 1.00, blue: 0.80)
            )
        case .gold:
            return ThemeColors(
                black: Color(red: 0.09, green: 0.07, blue: 0.03),
                darkGray: Color(red: 0.16, green: 0.12, blue: 0.05),
                midGray: Color(red: 0.26, green: 0.20, blue: 0.08),
                lightGray: Color(red: 0.40, green: 0.32, blue: 0.14),
                accent: Color(red: 0.98, green: 0.82, blue: 0.34),
                accentSecondary: Color(red: 0.72, green: 0.54, blue: 0.16),
                glow: Color(red: 1.00, green: 0.92, blue: 0.56)
            )
        case .plum:
            return ThemeColors(
                black: Color(red: 0.08, green: 0.04, blue: 0.10),
                darkGray: Color(red: 0.15, green: 0.08, blue: 0.18),
                midGray: Color(red: 0.24, green: 0.13, blue: 0.28),
                lightGray: Color(red: 0.38, green: 0.22, blue: 0.44),
                accent: Color(red: 0.86, green: 0.52, blue: 0.96),
                accentSecondary: Color(red: 0.58, green: 0.28, blue: 0.68),
                glow: Color(red: 0.96, green: 0.70, blue: 1.00)
            )
        case .sky:
            return ThemeColors(
                black: Color(red: 0.03, green: 0.07, blue: 0.12),
                darkGray: Color(red: 0.06, green: 0.13, blue: 0.22),
                midGray: Color(red: 0.10, green: 0.20, blue: 0.32),
                lightGray: Color(red: 0.16, green: 0.32, blue: 0.48),
                accent: Color(red: 0.52, green: 0.82, blue: 1.00),
                accentSecondary: Color(red: 0.26, green: 0.52, blue: 0.82),
                glow: Color(red: 0.72, green: 0.92, blue: 1.00)
            )
        case .bronze:
            return ThemeColors(
                black: Color(red: 0.09, green: 0.06, blue: 0.04),
                darkGray: Color(red: 0.16, green: 0.11, blue: 0.07),
                midGray: Color(red: 0.26, green: 0.18, blue: 0.11),
                lightGray: Color(red: 0.40, green: 0.28, blue: 0.18),
                accent: Color(red: 0.92, green: 0.64, blue: 0.36),
                accentSecondary: Color(red: 0.66, green: 0.40, blue: 0.20),
                glow: Color(red: 1.00, green: 0.78, blue: 0.48)
            )
        case .peach:
            return ThemeColors(
                black: Color(red: 0.11, green: 0.07, blue: 0.05),
                darkGray: Color(red: 0.19, green: 0.12, blue: 0.08),
                midGray: Color(red: 0.30, green: 0.19, blue: 0.13),
                lightGray: Color(red: 0.46, green: 0.30, blue: 0.20),
                accent: Color(red: 1.00, green: 0.70, blue: 0.52),
                accentSecondary: Color(red: 0.78, green: 0.44, blue: 0.30),
                glow: Color(red: 1.00, green: 0.84, blue: 0.68)
            )
        case .ruby:
            return ThemeColors(
                black: Color(red: 0.09, green: 0.02, blue: 0.04),
                darkGray: Color(red: 0.16, green: 0.04, blue: 0.07),
                midGray: Color(red: 0.25, green: 0.08, blue: 0.12),
                lightGray: Color(red: 0.40, green: 0.14, blue: 0.19),
                accent: Color(red: 0.95, green: 0.28, blue: 0.42),
                accentSecondary: Color(red: 0.66, green: 0.12, blue: 0.22),
                glow: Color(red: 1.00, green: 0.50, blue: 0.62)
            )
        case .magenta:
            return ThemeColors(
                black: Color(red: 0.09, green: 0.03, blue: 0.09),
                darkGray: Color(red: 0.16, green: 0.06, blue: 0.16),
                midGray: Color(red: 0.26, green: 0.10, blue: 0.26),
                lightGray: Color(red: 0.42, green: 0.18, blue: 0.42),
                accent: Color(red: 1.00, green: 0.46, blue: 0.92),
                accentSecondary: Color(red: 0.72, green: 0.22, blue: 0.68),
                glow: Color(red: 1.00, green: 0.68, blue: 0.98)
            )
        case .fuchsia:
            return ThemeColors(
                black: Color(red: 0.08, green: 0.03, blue: 0.11),
                darkGray: Color(red: 0.15, green: 0.06, blue: 0.19),
                midGray: Color(red: 0.24, green: 0.10, blue: 0.31),
                lightGray: Color(red: 0.39, green: 0.17, blue: 0.49),
                accent: Color(red: 0.94, green: 0.42, blue: 1.00),
                accentSecondary: Color(red: 0.64, green: 0.22, blue: 0.78),
                glow: Color(red: 1.00, green: 0.66, blue: 1.00)
            )
        case .orchid:
            return ThemeColors(
                black: Color(red: 0.07, green: 0.04, blue: 0.10),
                darkGray: Color(red: 0.13, green: 0.08, blue: 0.17),
                midGray: Color(red: 0.22, green: 0.13, blue: 0.27),
                lightGray: Color(red: 0.36, green: 0.22, blue: 0.43),
                accent: Color(red: 0.88, green: 0.62, blue: 1.00),
                accentSecondary: Color(red: 0.58, green: 0.36, blue: 0.72),
                glow: Color(red: 0.96, green: 0.78, blue: 1.00)
            )
        case .grape:
            return ThemeColors(
                black: Color(red: 0.05, green: 0.03, blue: 0.10),
                darkGray: Color(red: 0.10, green: 0.06, blue: 0.18),
                midGray: Color(red: 0.17, green: 0.10, blue: 0.29),
                lightGray: Color(red: 0.29, green: 0.18, blue: 0.45),
                accent: Color(red: 0.66, green: 0.50, blue: 0.96),
                accentSecondary: Color(red: 0.42, green: 0.28, blue: 0.68),
                glow: Color(red: 0.82, green: 0.70, blue: 1.00)
            )
        case .cobalt:
            return ThemeColors(
                black: Color(red: 0.02, green: 0.04, blue: 0.10),
                darkGray: Color(red: 0.05, green: 0.09, blue: 0.19),
                midGray: Color(red: 0.08, green: 0.15, blue: 0.31),
                lightGray: Color(red: 0.14, green: 0.25, blue: 0.50),
                accent: Color(red: 0.35, green: 0.62, blue: 1.00),
                accentSecondary: Color(red: 0.18, green: 0.36, blue: 0.78),
                glow: Color(red: 0.56, green: 0.78, blue: 1.00)
            )
        case .sapphire:
            return ThemeColors(
                black: Color(red: 0.02, green: 0.05, blue: 0.12),
                darkGray: Color(red: 0.04, green: 0.10, blue: 0.21),
                midGray: Color(red: 0.07, green: 0.17, blue: 0.34),
                lightGray: Color(red: 0.12, green: 0.28, blue: 0.52),
                accent: Color(red: 0.42, green: 0.78, blue: 1.00),
                accentSecondary: Color(red: 0.18, green: 0.46, blue: 0.78),
                glow: Color(red: 0.62, green: 0.88, blue: 1.00)
            )
        case .aqua:
            return ThemeColors(
                black: Color(red: 0.02, green: 0.08, blue: 0.10),
                darkGray: Color(red: 0.04, green: 0.14, blue: 0.17),
                midGray: Color(red: 0.07, green: 0.23, blue: 0.27),
                lightGray: Color(red: 0.12, green: 0.38, blue: 0.43),
                accent: Color(red: 0.36, green: 0.92, blue: 1.00),
                accentSecondary: Color(red: 0.16, green: 0.60, blue: 0.70),
                glow: Color(red: 0.58, green: 1.00, blue: 1.00)
            )
        case .lagoon:
            return ThemeColors(
                black: Color(red: 0.02, green: 0.08, blue: 0.08),
                darkGray: Color(red: 0.04, green: 0.14, blue: 0.14),
                midGray: Color(red: 0.07, green: 0.23, blue: 0.22),
                lightGray: Color(red: 0.13, green: 0.37, blue: 0.35),
                accent: Color(red: 0.38, green: 0.88, blue: 0.82),
                accentSecondary: Color(red: 0.16, green: 0.58, blue: 0.56),
                glow: Color(red: 0.60, green: 1.00, blue: 0.94)
            )
        case .jade:
            return ThemeColors(
                black: Color(red: 0.02, green: 0.08, blue: 0.05),
                darkGray: Color(red: 0.05, green: 0.14, blue: 0.10),
                midGray: Color(red: 0.08, green: 0.23, blue: 0.16),
                lightGray: Color(red: 0.14, green: 0.36, blue: 0.25),
                accent: Color(red: 0.44, green: 0.90, blue: 0.62),
                accentSecondary: Color(red: 0.20, green: 0.58, blue: 0.38),
                glow: Color(red: 0.64, green: 1.00, blue: 0.78)
            )
        case .lime:
            return ThemeColors(
                black: Color(red: 0.06, green: 0.09, blue: 0.03),
                darkGray: Color(red: 0.11, green: 0.16, blue: 0.05),
                midGray: Color(red: 0.18, green: 0.26, blue: 0.08),
                lightGray: Color(red: 0.30, green: 0.40, blue: 0.13),
                accent: Color(red: 0.78, green: 0.96, blue: 0.36),
                accentSecondary: Color(red: 0.50, green: 0.66, blue: 0.18),
                glow: Color(red: 0.90, green: 1.00, blue: 0.58)
            )
        case .olive:
            return ThemeColors(
                black: Color(red: 0.07, green: 0.08, blue: 0.04),
                darkGray: Color(red: 0.13, green: 0.14, blue: 0.07),
                midGray: Color(red: 0.21, green: 0.23, blue: 0.12),
                lightGray: Color(red: 0.34, green: 0.36, blue: 0.20),
                accent: Color(red: 0.76, green: 0.82, blue: 0.46),
                accentSecondary: Color(red: 0.50, green: 0.54, blue: 0.24),
                glow: Color(red: 0.88, green: 0.94, blue: 0.62)
            )
        case .moss:
            return ThemeColors(
                black: Color(red: 0.05, green: 0.08, blue: 0.04),
                darkGray: Color(red: 0.09, green: 0.14, blue: 0.08),
                midGray: Color(red: 0.15, green: 0.23, blue: 0.13),
                lightGray: Color(red: 0.25, green: 0.36, blue: 0.22),
                accent: Color(red: 0.58, green: 0.78, blue: 0.44),
                accentSecondary: Color(red: 0.36, green: 0.52, blue: 0.26),
                glow: Color(red: 0.74, green: 0.92, blue: 0.58)
            )
        case .lemon:
            return ThemeColors(
                black: Color(red: 0.09, green: 0.08, blue: 0.03),
                darkGray: Color(red: 0.16, green: 0.14, blue: 0.05),
                midGray: Color(red: 0.26, green: 0.23, blue: 0.08),
                lightGray: Color(red: 0.40, green: 0.36, blue: 0.14),
                accent: Color(red: 1.00, green: 0.92, blue: 0.36),
                accentSecondary: Color(red: 0.72, green: 0.62, blue: 0.16),
                glow: Color(red: 1.00, green: 0.98, blue: 0.58)
            )
        case .tangerine:
            return ThemeColors(
                black: Color(red: 0.10, green: 0.06, blue: 0.03),
                darkGray: Color(red: 0.18, green: 0.10, blue: 0.05),
                midGray: Color(red: 0.29, green: 0.16, blue: 0.08),
                lightGray: Color(red: 0.46, green: 0.26, blue: 0.14),
                accent: Color(red: 1.00, green: 0.64, blue: 0.28),
                accentSecondary: Color(red: 0.76, green: 0.38, blue: 0.14),
                glow: Color(red: 1.00, green: 0.80, blue: 0.46)
            )
        case .pumpkin:
            return ThemeColors(
                black: Color(red: 0.10, green: 0.05, blue: 0.02),
                darkGray: Color(red: 0.18, green: 0.09, blue: 0.04),
                midGray: Color(red: 0.29, green: 0.15, blue: 0.06),
                lightGray: Color(red: 0.45, green: 0.24, blue: 0.10),
                accent: Color(red: 1.00, green: 0.52, blue: 0.20),
                accentSecondary: Color(red: 0.72, green: 0.30, blue: 0.10),
                glow: Color(red: 1.00, green: 0.70, blue: 0.38)
            )
        case .espresso:
            return ThemeColors(
                black: Color(red: 0.06, green: 0.04, blue: 0.03),
                darkGray: Color(red: 0.12, green: 0.08, blue: 0.06),
                midGray: Color(red: 0.20, green: 0.14, blue: 0.10),
                lightGray: Color(red: 0.32, green: 0.23, blue: 0.16),
                accent: Color(red: 0.78, green: 0.58, blue: 0.42),
                accentSecondary: Color(red: 0.50, green: 0.34, blue: 0.24),
                glow: Color(red: 0.94, green: 0.72, blue: 0.54)
            )
        case .mocha:
            return ThemeColors(
                black: Color(red: 0.07, green: 0.05, blue: 0.04),
                darkGray: Color(red: 0.13, green: 0.10, blue: 0.08),
                midGray: Color(red: 0.22, green: 0.17, blue: 0.13),
                lightGray: Color(red: 0.35, green: 0.27, blue: 0.20),
                accent: Color(red: 0.86, green: 0.66, blue: 0.50),
                accentSecondary: Color(red: 0.58, green: 0.42, blue: 0.30),
                glow: Color(red: 1.00, green: 0.82, blue: 0.64)
            )
        case .pearl:
            return ThemeColors(
                black: Color(red: 0.06, green: 0.06, blue: 0.07),
                darkGray: Color(red: 0.12, green: 0.12, blue: 0.14),
                midGray: Color(red: 0.20, green: 0.20, blue: 0.22),
                lightGray: Color(red: 0.33, green: 0.33, blue: 0.36),
                accent: Color(red: 0.92, green: 0.88, blue: 0.82),
                accentSecondary: Color(red: 0.62, green: 0.58, blue: 0.52),
                glow: Color(red: 1.00, green: 0.96, blue: 0.90)
            )
        case .cyber:
            return ThemeColors(
                black: Color(red: 0.02, green: 0.05, blue: 0.06),
                darkGray: Color(red: 0.04, green: 0.10, blue: 0.12),
                midGray: Color(red: 0.07, green: 0.18, blue: 0.20),
                lightGray: Color(red: 0.12, green: 0.30, blue: 0.34),
                accent: Color(red: 0.42, green: 1.00, blue: 0.72),
                accentSecondary: Color(red: 0.16, green: 0.72, blue: 0.86),
                glow: Color(red: 0.66, green: 1.00, blue: 0.90)
            )
        case .ultraviolet:
            return ThemeColors(
                black: Color(red: 0.04, green: 0.03, blue: 0.12),
                darkGray: Color(red: 0.08, green: 0.06, blue: 0.22),
                midGray: Color(red: 0.14, green: 0.10, blue: 0.34),
                lightGray: Color(red: 0.24, green: 0.18, blue: 0.54),
                accent: Color(red: 0.70, green: 0.46, blue: 1.00),
                accentSecondary: Color(red: 0.38, green: 0.24, blue: 0.86),
                glow: Color(red: 0.86, green: 0.66, blue: 1.00)
            )
        case .aurora:
            return ThemeColors(
                black: Color(red: 0.03, green: 0.07, blue: 0.09),
                darkGray: Color(red: 0.05, green: 0.13, blue: 0.16),
                midGray: Color(red: 0.09, green: 0.21, blue: 0.25),
                lightGray: Color(red: 0.16, green: 0.34, blue: 0.40),
                accent: Color(red: 0.58, green: 0.96, blue: 0.78),
                accentSecondary: Color(red: 0.42, green: 0.54, blue: 0.96),
                glow: Color(red: 0.80, green: 1.00, blue: 0.92)
            )
        case .borealis:
            return ThemeColors(
                black: Color(red: 0.02, green: 0.06, blue: 0.08),
                darkGray: Color(red: 0.04, green: 0.12, blue: 0.15),
                midGray: Color(red: 0.07, green: 0.20, blue: 0.24),
                lightGray: Color(red: 0.12, green: 0.34, blue: 0.38),
                accent: Color(red: 0.46, green: 1.00, blue: 0.70),
                accentSecondary: Color(red: 0.35, green: 0.58, blue: 1.00),
                glow: Color(red: 0.78, green: 1.00, blue: 0.88)
            )
        case .nebula:
            return ThemeColors(
                black: Color(red: 0.05, green: 0.03, blue: 0.11),
                darkGray: Color(red: 0.10, green: 0.06, blue: 0.20),
                midGray: Color(red: 0.18, green: 0.10, blue: 0.32),
                lightGray: Color(red: 0.30, green: 0.18, blue: 0.50),
                accent: Color(red: 0.58, green: 0.88, blue: 1.00),
                accentSecondary: Color(red: 0.88, green: 0.44, blue: 1.00),
                glow: Color(red: 0.76, green: 1.00, blue: 0.92)
            )
        case .prism:
            return ThemeColors(
                black: Color(red: 0.04, green: 0.05, blue: 0.09),
                darkGray: Color(red: 0.08, green: 0.10, blue: 0.16),
                midGray: Color(red: 0.13, green: 0.17, blue: 0.26),
                lightGray: Color(red: 0.22, green: 0.28, blue: 0.40),
                accent: Color(red: 0.98, green: 0.64, blue: 0.42),
                accentSecondary: Color(red: 0.44, green: 0.84, blue: 1.00),
                glow: Color(red: 0.76, green: 1.00, blue: 0.66)
            )
        case .opal:
            return ThemeColors(
                black: Color(red: 0.04, green: 0.07, blue: 0.09),
                darkGray: Color(red: 0.08, green: 0.13, blue: 0.16),
                midGray: Color(red: 0.13, green: 0.21, blue: 0.24),
                lightGray: Color(red: 0.22, green: 0.34, blue: 0.38),
                accent: Color(red: 0.78, green: 0.98, blue: 0.92),
                accentSecondary: Color(red: 0.72, green: 0.58, blue: 1.00),
                glow: Color(red: 1.00, green: 0.82, blue: 0.72)
            )
        case .solstice:
            return ThemeColors(
                black: Color(red: 0.08, green: 0.05, blue: 0.09),
                darkGray: Color(red: 0.15, green: 0.09, blue: 0.16),
                midGray: Color(red: 0.24, green: 0.15, blue: 0.25),
                lightGray: Color(red: 0.38, green: 0.24, blue: 0.39),
                accent: Color(red: 1.00, green: 0.72, blue: 0.36),
                accentSecondary: Color(red: 0.74, green: 0.44, blue: 1.00),
                glow: Color(red: 1.00, green: 0.92, blue: 0.62)
            )
        case .ion:
            return ThemeColors(
                black: Color(red: 0.02, green: 0.05, blue: 0.08),
                darkGray: Color(red: 0.04, green: 0.10, blue: 0.16),
                midGray: Color(red: 0.07, green: 0.17, blue: 0.27),
                lightGray: Color(red: 0.12, green: 0.28, blue: 0.44),
                accent: Color(red: 0.36, green: 0.92, blue: 1.00),
                accentSecondary: Color(red: 0.68, green: 0.42, blue: 1.00),
                glow: Color(red: 0.52, green: 1.00, blue: 0.78)
            )
        case .dream:
            return ThemeColors(
                black: Color(red: 0.05, green: 0.04, blue: 0.10),
                darkGray: Color(red: 0.10, green: 0.08, blue: 0.18),
                midGray: Color(red: 0.17, green: 0.13, blue: 0.28),
                lightGray: Color(red: 0.28, green: 0.22, blue: 0.44),
                accent: Color(red: 0.78, green: 0.70, blue: 1.00),
                accentSecondary: Color(red: 0.44, green: 0.76, blue: 1.00),
                glow: Color(red: 1.00, green: 0.74, blue: 0.92)
            )
        case .polar:
            return ThemeColors(
                black: Color(red: 0.03, green: 0.06, blue: 0.10),
                darkGray: Color(red: 0.06, green: 0.11, blue: 0.18),
                midGray: Color(red: 0.10, green: 0.18, blue: 0.29),
                lightGray: Color(red: 0.17, green: 0.30, blue: 0.45),
                accent: Color(red: 0.70, green: 0.94, blue: 1.00),
                accentSecondary: Color(red: 0.40, green: 0.58, blue: 1.00),
                glow: Color(red: 0.92, green: 1.00, blue: 1.00)
            )
        }
    }
}

struct ThemeColors {
    let black: Color
    let darkGray: Color
    let midGray: Color
    let lightGray: Color
    let accent: Color
    let accentSecondary: Color
    let glow: Color
}

enum AppTheme {
    static let themeKey = "app.selectedColorTheme"
    static let defaultTheme: AppColorTheme = .graphite

    static var selectedTheme: AppColorTheme {
        let rawValue = UserDefaults.standard.string(forKey: themeKey)
        return rawValue.flatMap(AppColorTheme.init(rawValue:)) ?? defaultTheme
    }

    static func colors(for theme: AppColorTheme) -> ThemeColors {
        theme.colors
    }

    private static var colors: ThemeColors {
        selectedTheme.colors
    }

    static var black: Color { colors.black }
    static var darkGray: Color { colors.darkGray }
    static var midGray: Color { colors.midGray }
    static var lightGray: Color { colors.lightGray }
    static var silver: Color { AppColorTheme.graphite.colors.accent }

    static var accent: Color { colors.accent }
    static var accentSecondary: Color { colors.accentSecondary }
    static var glow: Color { colors.glow }

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.82)

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                black,
                darkGray,
                accentSecondary.opacity(0.22),
                midGray.opacity(0.94),
                glow.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Cards and panels — slightly translucent so background waves peek through.
    static var cardFill: Color {
        midGray.opacity(0.84)
    }

    static var cardTint: Color {
        accent.opacity(0.07)
    }

    static var cardStroke: Color {
        lightGray.opacity(0.42)
    }

    static var cardStrokeAccent: Color {
        accent.opacity(0.18)
    }

    /// List rows pick up a hint of the palette without going loud.
    static var rowFill: Color {
        darkGray.opacity(0.92)
    }

    static var rowTint: Color {
        accentSecondary.opacity(0.05)
    }

    static var pillFill: Color {
        lightGray.opacity(0.40)
    }

    static var pillTint: Color {
        accent.opacity(0.10)
    }

    /// Buttons stay neutral gray — they don't shift with accent colors.
    static var buttonFill: Color {
        Color(red: 0.11, green: 0.11, blue: 0.12)
    }

    static var buttonFillProminent: Color {
        Color(red: 0.22, green: 0.22, blue: 0.24)
    }
}

extension View {
    func themedRowBackground(cornerRadius: CGFloat = 12) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(AppTheme.rowFill)
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(AppTheme.rowTint)
                }
        }
    }
}

struct ModernCard<Content: View, Trailing: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let trailing: () -> Trailing
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        systemImage: String,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() },
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.trailing = trailing
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent.opacity(0.85))
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer(minLength: 0)
                trailing()
            }

            content()
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.cardFill)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppTheme.cardTint)
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [AppTheme.cardStrokeAccent, AppTheme.cardStroke],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}

struct StatusPill: View {
    let text: String
    @AppStorage(AppTheme.themeKey) private var themeRawValue = AppTheme.defaultTheme.rawValue

    private var theme: AppColorTheme {
        AppColorTheme(rawValue: themeRawValue) ?? AppTheme.defaultTheme
    }

    var body: some View {
        let colors = theme.colors
        Text(text)
            .font(.subheadline)
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill(colors.lightGray.opacity(0.40))
                    .overlay {
                        Capsule()
                            .fill(colors.accent.opacity(0.10))
                    }
            }
    }
}

struct CountBadge: View {
    let count: Int

    var body: some View {
        Text("\(count)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppTheme.lightGray.opacity(0.75), in: Capsule())
    }
}

struct FormatBadge: View {
    let label: String
    let quality: String?

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)

            if let quality = quality {
                Text(quality)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(AppTheme.lightGray.opacity(0.75), in: Capsule())
    }
}

struct IconCircle: View {
    let systemName: String
    let size: CGFloat
    @AppStorage(AppTheme.themeKey) private var themeRawValue = AppTheme.defaultTheme.rawValue

    private var theme: AppColorTheme {
        AppColorTheme(rawValue: themeRawValue) ?? AppTheme.defaultTheme
    }

    var body: some View {
        let colors = theme.colors
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            colors.lightGray.opacity(0.85),
                            colors.accentSecondary.opacity(0.55),
                            colors.glow.opacity(0.35)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            Image(systemName: systemName)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .shadow(color: colors.accent.opacity(0.25), radius: 12, y: 6)
        .shadow(color: Color.black.opacity(0.35), radius: 8, y: 4)
    }
}

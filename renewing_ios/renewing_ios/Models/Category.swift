import Foundation

enum ListingCategory: String, CaseIterable, Identifiable {
    case materials
    case tools

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .materials: return "Материалы"
        case .tools: return "Инструменты"
        }
    }

    var subcategories: [String] {
        switch self {
        case .materials:
            return [
                "Цемент / бетонная смесь",
                "Краска / грунтовка",
                "Плитка / керамика",
                "Дерево / пиломатериалы",
                "Гипсокартон / штукатурка",
                "Утеплитель",
                "Трубы / сантехника",
                "Электрика",
                "Клеи / герметики",
                "Песок / щебень",
                "Обои",
                "Напольное покрытие",
                "Другие материалы",
            ]
        case .tools:
            return [
                "Дрели",
                "Пилы",
                "Шлифмашины",
                "Миксеры",
                "Лестницы",
                "Измерительные инструменты",
                "Ручные инструменты",
                "Малярные инструменты",
                "Инструменты для плитки",
                "Сварочное оборудование",
                "Средства защиты",
                "Другие инструменты",
            ]
        }
    }
}

enum ListingUnit: String, CaseIterable, Identifiable {
    case kg, g, pieces, bags, liters, meters, sq_meters, boxes, sets, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .kg: return "кг"
        case .g: return "г"
        case .pieces: return "шт"
        case .bags: return "мешк."
        case .liters: return "л"
        case .meters: return "м"
        case .sq_meters: return "м\u{00B2}"
        case .boxes: return "кор."
        case .sets: return "набор"
        case .other: return "другое"
        }
    }
}

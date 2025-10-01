import Testing
@testable import MetroidvaniaKit

@Suite struct ParseColorTests {
    @Test(arguments: ["#00000000", "00000000"], HexColorFormat.allCases)
    func parseZero(hexString: String, format: HexColorFormat) async throws {
        let color = try #require(parseHexColor(hexString))
        #expect(color.r == 0.0)
        #expect(color.g == 0.0)
        #expect(color.b == 0.0)
        #expect(color.a == 0.0)
    }

    @Test(arguments: ["", "#5", "#", "00000", "#000000000"], HexColorFormat.allCases)
    func parseInvalidValues(hexString: String, format: HexColorFormat) async throws {
        #expect(parseHexColor(hexString, format: format) == nil)
    }

    @Test(arguments: ["#000000", "000000"], HexColorFormat.allCases)
    func parseNoAlpha(hexString: String, format: HexColorFormat) async throws {
        let color = try #require(parseHexColor(hexString, format: format))
        #expect(color.a == 1.0)
    }

    @Test(arguments: zip(["#FFFFFF00", "#00FFFFFF"], HexColorFormat.allCases))
    func parseAlpha(hexString: String, format: HexColorFormat) async throws {
        let color = try #require(parseHexColor(hexString, format: format))
        #expect(color.r == 1.0)
        #expect(color.g == 1.0)
        #expect(color.b == 1.0)
        #expect(color.a == 0.0)
    }

    @Test(arguments: zip(["#FF000000", "#00FF0000"], HexColorFormat.allCases))
    func parseRed(hexString: String, format: HexColorFormat) async throws {
        let color = try #require(parseHexColor(hexString, format: format))
        #expect(color.r == 1.0)
        #expect(color.g == 0.0)
        #expect(color.b == 0.0)
        #expect(color.a == 0.0)
    }

    @Test(arguments: zip(["#00FF0000", "#0000FF00"], HexColorFormat.allCases))
    func parseGreen(hexString: String, format: HexColorFormat) async throws {
        let color = try #require(parseHexColor(hexString, format: format))
        #expect(color.r == 0.0)
        #expect(color.g == 1.0)
        #expect(color.b == 0.0)
        #expect(color.a == 0.0)
    }

    @Test(arguments: zip(["#0000FF00", "#000000FF"], HexColorFormat.allCases))
    func parseBlue(hexString: String, format: HexColorFormat) async throws {
        let color = try #require(parseHexColor(hexString, format: format))
        #expect(color.r == 0.0)
        #expect(color.g == 0.0)
        #expect(color.b == 1.0)
        #expect(color.a == 0.0)
    }
}
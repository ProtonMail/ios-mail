//
//  ProtonColorPalettemacOSV5.swift
//  ProtonCore-UIFoundations - Created on 04.11.20.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

public struct ProtonColorPalettemacOS {
    static let instance = ProtonColorPalettemacOS()

    private init() {}
    
    // MARK: - Backdrop
    public let BackdropNorm = ProtonColor(name: "ProtonCarbonBackdropNorm")
    
    // MARK: - Background
    public let BackgroundNorm = ProtonColor(name: "ProtonCarbonBackgroundNorm")
    public let BackgroundStrong = ProtonColor(name: "ProtonCarbonBackgroundStrong")
    public let BackgroundWeak = ProtonColor(name: "ProtonCarbonBackgroundWeak")
    
    // MARK: - Border
    public let BorderNorm = ProtonColor(name: "ProtonCarbonBorderNorm")
    public let BorderWeak = ProtonColor(name: "ProtonCarbonBorderWeak")
    
    // MARK: - Field
    public let FieldDisabled = ProtonColor(name: "ProtonCarbonFieldDisabled")
    public let FieldFocus = ProtonColor(name: "ProtonCarbonFieldFocus")
    public let FieldHighlight = ProtonColor(name: "ProtonCarbonFieldHighlight")
    public let FieldHighlightError = ProtonColor(name: "ProtonCarbonFieldHighlightError")
    public let FieldHover = ProtonColor(name: "ProtonCarbonFieldHover")
    public let FieldNorm = ProtonColor(name: "ProtonCarbonFieldNorm")
    
    // MARK: - Interaction
    public let InteractionDefault = ProtonColor(name: "ProtonCarbonInteractionDefault")
    public let InteractionDefaultActive = ProtonColor(name: "ProtonCarbonInteractionDefaultActive")
    public let InteractionDefaultHover = ProtonColor(name: "ProtonCarbonInteractionDefaultHover")
    public let InteractionNorm = ProtonColor(name: "ProtonCarbonInteractionNorm")
    public let InteractionNormActive = ProtonColor(name: "ProtonCarbonInteractionNormActive")
    public let InteractionNormHover = ProtonColor(name: "ProtonCarbonInteractionNormHover")
    public let InteractionWeak = ProtonColor(name: "ProtonCarbonInteractionWeak")
    public let InteractionWeakActive = ProtonColor(name: "ProtonCarbonInteractionWeakActive")
    public let InteractionWeakHover = ProtonColor(name: "ProtonCarbonInteractionWeakHover")
    
    // MARK: - Link
    public let LinkActive = ProtonColor(name: "ProtonCarbonLinkActive")
    public let LinkHover = ProtonColor(name: "ProtonCarbonLinkHover")
    public let LinkNorm = ProtonColor(name: "ProtonCarbonLinkNorm")
    
    // MARK: - Primary
    public let Primary = ProtonColor(name: "ProtonCarbonPrimary")
    
    // MARK: - Shade
    public let Shade0 = ProtonColor(name: "ProtonCarbonShade0")
    public let Shade10 = ProtonColor(name: "ProtonCarbonShade10")
    public let Shade20 = ProtonColor(name: "ProtonCarbonShade20")
    public let Shade40 = ProtonColor(name: "ProtonCarbonShade40")
    public let Shade50 = ProtonColor(name: "ProtonCarbonShade50")
    public let Shade60 = ProtonColor(name: "ProtonCarbonShade60")
    public let Shade80 = ProtonColor(name: "ProtonCarbonShade80")
    public let Shade100 = ProtonColor(name: "ProtonCarbonShade100")
    
    // MARK: - Shadow
    public let ShadowLifted = ProtonColor(name: "ProtonCarbonShadowLifted")
    public let ShadowNorm = ProtonColor(name: "ProtonCarbonShadowNorm")
    
    // MARK: - Signal
    public let SignalDanger = ProtonColor(name: "ProtonCarbonSignalDanger")
    public let SignalDangerActive = ProtonColor(name: "ProtonCarbonSignalDangerActive")
    public let SignalDangerHover = ProtonColor(name: "ProtonCarbonSignalDangerHover")
    public let SignalInfo = ProtonColor(name: "ProtonCarbonSignalInfo")
    public let SignalInfoActive = ProtonColor(name: "ProtonCarbonSignalInfoActive")
    public let SignalInfoHover = ProtonColor(name: "ProtonCarbonSignalInfoHover")
    public let SignalSuccess = ProtonColor(name: "ProtonCarbonSignalSuccess")
    public let SignalSuccessActive = ProtonColor(name: "ProtonCarbonSignalSuccessActive")
    public let SignalSuccessHover = ProtonColor(name: "ProtonCarbonSignalSuccessHover")
    public let SignalWarning = ProtonColor(name: "ProtonCarbonSignalWarning")
    public let SignalWarningActive = ProtonColor(name: "ProtonCarbonSignalWarningActive")
    public let SignalWarningHover = ProtonColor(name: "ProtonCarbonSignalWarningHover")
    
    // MARK: - Text
    public let TextDisabled = ProtonColor(name: "ProtonCarbonTextDisabled")
    public let TextHint = ProtonColor(name: "ProtonCarbonTextHint")
    public let TextInvert = ProtonColor(name: "ProtonCarbonTextInvert")
    public let TextNorm = ProtonColor(name: "ProtonCarbonTextNorm")
    public let TextWeak = ProtonColor(name: "ProtonCarbonTextWeak")
    
    // MARK: Accent
    public let PurpleBase = ProtonColor(name: "SharedPurpleBase")
    public let EnzianBase = ProtonColor(name: "SharedEnzianBase")
    public let PinkBase = ProtonColor(name: "SharedPinkBase")
    public let PlumBase = ProtonColor(name: "SharedPlumBase")
    public let StrawberryBase = ProtonColor(name: "SharedStrawberryBase")
    public let CeriseBase = ProtonColor(name: "SharedCeriseBase")
    public let CarrotBase = ProtonColor(name: "SharedCarrotBase")
    public let CopperBase = ProtonColor(name: "SharedCopperBase")
    public let SaharaBase = ProtonColor(name: "SharedSaharaBase")
    public let SoilBase = ProtonColor(name: "SharedSoilBase")
    public let SlateblueBase = ProtonColor(name: "SharedSlateblueBase")
    public let CobaltBase = ProtonColor(name: "SharedCobaltBase")
    public let PacificBase = ProtonColor(name: "SharedPacificBase")
    public let OceanBase = ProtonColor(name: "SharedOceanBase")
    public let ReefBase = ProtonColor(name: "SharedReefBase")
    public let PineBase = ProtonColor(name: "SharedPineBase")
    public let FernBase = ProtonColor(name: "SharedFernBase")
    public let ForestBase = ProtonColor(name: "SharedForestBase")
    public let OliveBase = ProtonColor(name: "SharedOliveBase")
    public let PickleBase = ProtonColor(name: "SharedPickleBase")
    
    // MARK: Two special colors that consistently occur in designs even though they are not part af the palette
    public let White = ProtonColor(name: "White")
    public let Black = ProtonColor(name: "Black")
}

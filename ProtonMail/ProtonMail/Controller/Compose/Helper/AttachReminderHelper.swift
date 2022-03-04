// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation

struct AttachReminderHelper {
    static let FR_REGEX = "voir pi\u{00e8}ce jointe|voir pi\u{00e8}ces jointes|voir fichier joint|voir fichiers joints|voir fichier associ\u{00e9}|voir fichiers associ\u{00e9}s|joint|joints|jointe|jointes|joint \u{00e0} cet e-mail|jointe \u{00e0} cet e-mail|joints \u{00e0} cet e-mail|jointes \u{00e0} cet e-mail|joint \u{00e0} ce message|jointe \u{00e0} ce message|joints \u{00e0} ce message|jointes \u{00e0} ce message|je joins|j'ai joint|ci-joint|pi\u{00e8}ce jointe|pi\u{00e8}ces jointes|fichier joint|fichiers joints|voir le fichier joint|voir les fichiers joints|voir la pi\u{00e8}ce jointe|voir les pi\u{00e8}ces jointes"
    static let EN_REGEX = "see attached|see attachment|see included|is attached|attached is|are attached|attached are|attached to this email|attached to this message|I'm attaching|I am attaching|I've attached|I have attached|I attach|I attached|find attached|find the attached|find included|find the included|attached file|see the attached|see attachments|attached files|see the attachment|here is the attachment|attached you will find"
    static let DE_REGEX = "siehe Anhang|angeh\u{00e4}ngt|anbei|hinzugef\u{00fc}gt|ist angeh\u{00e4}ngt|angeh\u{00e4}ngt ist|sind angeh\u{00e4}ngt|angeh\u{00e4}ngt sind|an diese E-Mail angeh\u{00e4}ngt|an diese Nachricht angeh\u{00e4}ngt|Anhang hinzuf\u{00fc}gen|Anhang anbei|Anhang hinzugef\u{00fc}gt|anbei finden|anbei|im Anhang|mit dieser E-Mail sende ich|angeh\u{00e4}ngte Datei|siehe angeh\u{00e4}ngte Datei|siehe Anh\u{00e4}nge|angeh\u{00e4}ngte Dateien|siehe Anlage|siehe Anlagen"
    static let ES_REGEX = "ver adjunto|ver archivo adjunto|ver archivo incluido|se ha adjuntado|adjuntado|se han adjuntado|adjuntados|se ha adjuntado a este correo|se ha adjuntado a este mensaje|Adjunto te env\u{00ed}o|He adjuntado|He adjuntado un archivo|adjunto|adjunto el archivo|incluyo el archivo|archivo adjunto|mira el archivo adjunto|ver archivos adjuntos|archivos adjuntos|ver el archivo adjunto"
    static let RU_REGEX = "прикрепленный файл|прикреплённый файл|прикреплен|прикреплён|прикрепил|прикрепила"
    static let IT_REGEX = "vedi in allegato|vedi allegato|vedi accluso|\u{00e8} allegato|in allegato|sono allegati|in allegato vi sono|in allegato a questa email|in allegato a questo messaggio|invio in allegato|allego|ho allegato|in allegato trovi|trova in allegato|trova accluso|incluso troverai|file allegato|vedi allegato|vedi allegati|file allegati|vedi l'allegato|ti allego"
    static let PT_PT_REGEX = "ver em anexo|ver anexo|ver inclu\u{00ed}do|est\u{00e1} anexado|est\u{00e1} em anexo|est\u{00e3}o anexados|est\u{00e3}o em anexo|anexado a este email|anexado a esta mensagem|estou a anexar|anexo|anexei|anexei|anexo|anexei|queira encontrar em anexo|segue em anexo|encontra-se inclu\u{00ed}do|segue inclu\u{00ed}do|ficheiro anexado|ver o anexo|ver anexos|ficheiros anexados|ver o anexo"
    static let PT_BR_REGEX = "ver anexado|ver anexo|ver inclu\u{00ed}do|est\u{00e1} anexado|anexado|est\u{00e3}o anexados|anexados|anexado a este e-mail|anexado a esta mensagem|estou anexando|eu estou anexando|anexei|eu anexei|estou incluindo|eu estou incluindo|inclu\u{00ed}|eu inclu\u{00ed}|enviar anexo|enviar o anexo|enviar inclu\u{00ed}do|ver anexos|arquivo anexado|arquivos anexados|em anexo|anexo|veja em anexo|veja o anexo|veja os anexos"
    static let NL_REGEX = "zie bijgevoegd|zie bijlage|zie toegevoegd|is bijgevoegd|bijgevoegd is|zijn bijgevoegd|bijgevoegd zijn|toegevoegd aan dit e-mailbericht|toegevoegd aan dit bericht|Ik voeg bij|Ik heb bijgevoegd|Ik voeg een bijlage bij|Ik heb een bijlage bijgevoegd|bijlage bijvoegen|bijlagen bijvoegen|bijlage opgenomen|opgenomen bijlage|bijgevoegd bestand|zie de bijlage|zie bijlagen|bijgevoegde bestanden|de bijlage bekijken"
    static let PL_REGEX = "patrz w za\u{0142}\u{0105}czeniu|patrz za\u{0142}\u{0105}cznik|patrz do\u{0142}\u{0105}czony|jest do\u{0142}\u{0105}czony|w za\u{0142}\u{0105}czeniu|s\u{0105} za\u{0142}\u{0105}czone|za\u{0142}\u{0105}czone s\u{0105}|za\u{0142}\u{0105}czone do tego e-maila|do\u{0142}\u{0105}czone do tej wiadomo\u{015b}ci|do\u{0142}\u{0105}czam|za\u{0142}\u{0105}czam|za\u{0142}\u{0105}czy\u{0142}em|za\u{0142}\u{0105}czy\u{0142}am|dodaj\u{0119}|wysy\u{0142}am|do\u{0142}\u{0105}czy\u{0142}em|do\u{0142}\u{0105}czy\u{0142}am|patrz za\u{0142}\u{0105}czniki|w za\u{0142}\u{0105}czniku|patrz za\u{0142}\u{0105}czony|patrz za\u{0142}\u{0105}czone|masz w za\u{0142}\u{0105}czeniu|za\u{0142}\u{0105}czony plik|zobacz za\u{0142}\u{0105}cznik|zobacz za\u{0142}\u{0105}czniki|za\u{0142}\u{0105}czone pliki"

    static func hasAttachKeyword(content: String,
                                 language: ELanguage) -> Bool {
        switch language {
        case .english:
            return content.preg_match(AttachReminderHelper.EN_REGEX)
        case .german:
            return content.preg_match(AttachReminderHelper.DE_REGEX)
        case .french:
            return content.preg_match(AttachReminderHelper.FR_REGEX)
        case .russian:
            return content.preg_match(AttachReminderHelper.RU_REGEX)
        case .spanish:
            return content.preg_match(AttachReminderHelper.ES_REGEX)
        case .polish:
            return content.preg_match(AttachReminderHelper.PL_REGEX)
        case .dutch:
            return content.preg_match(AttachReminderHelper.NL_REGEX)
        case .italian:
            return content.preg_match(AttachReminderHelper.IT_REGEX)
        case .portugueseBrazil:
            return content.preg_match(AttachReminderHelper.PT_BR_REGEX)
        case .portuguese:
            return content.preg_match(AttachReminderHelper.PT_PT_REGEX)
        default:
            return false
        }
    }
}

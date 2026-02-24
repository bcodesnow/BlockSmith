#include "utils.h"
#include <QRandomGenerator>

namespace Utils {

QString generateHexId(int bits, const QString &prefix, const std::function<bool(const QString &)> &exists)
{
    auto *rng = QRandomGenerator::global();
    const quint32 bound = 1u << bits;           // e.g. 0x1000000 for 24 bits
    const int hexLen = (bits + 3) / 4;          // e.g. 6 for 24 bits

    QString id;
    do {
        quint32 val = rng->bounded(bound);
        id = prefix + QString::number(val, 16).rightJustified(hexLen, '0');
    } while (exists(id));
    return id;
}

QStringConverter::Encoding detectBomEncoding(QFile &file, bool &hasBom)
{
    QByteArray bom = file.peek(4);
    hasBom = false;

    if (bom.size() >= 3
        && static_cast<unsigned char>(bom[0]) == 0xEF
        && static_cast<unsigned char>(bom[1]) == 0xBB
        && static_cast<unsigned char>(bom[2]) == 0xBF) {
        hasBom = true;
        return QStringConverter::Utf8;
    }
    if (bom.size() >= 2
        && static_cast<unsigned char>(bom[0]) == 0xFF
        && static_cast<unsigned char>(bom[1]) == 0xFE) {
        hasBom = true;
        return QStringConverter::Utf16LE;
    }
    if (bom.size() >= 2
        && static_cast<unsigned char>(bom[0]) == 0xFE
        && static_cast<unsigned char>(bom[1]) == 0xFF) {
        hasBom = true;
        return QStringConverter::Utf16BE;
    }
    return QStringConverter::Utf8;
}

} // namespace Utils

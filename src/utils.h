#pragma once

#include <QString>
#include <QFile>
#include <QStringConverter>
#include <functional>

namespace Utils {

// Generate a random hex ID with optional prefix, avoiding collisions.
// bits = number of random bits (24 → 6 hex chars).
QString generateHexId(int bits, const QString &prefix, const std::function<bool(const QString &)> &exists);

// Detect encoding from BOM. Returns Utf8 for files without a BOM.
QStringConverter::Encoding detectBomEncoding(QFile &file, bool &hasBom);

// Path comparison utilities (case-insensitive on Windows, case-sensitive elsewhere)
Qt::CaseSensitivity pathCaseSensitivity();
QString normalizePath(const QString &path);
bool samePath(const QString &a, const QString &b);

} // namespace Utils

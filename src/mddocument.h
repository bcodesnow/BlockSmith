#pragma once

#include <QObject>
#include <QString>
#include <QList>
#include <QVariantList>
#include <QStringConverter>
#include <QtQml/qqmlregistration.h>

class MdDocument : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Use via AppController.currentDocument")

    Q_PROPERTY(QString filePath READ filePath NOTIFY filePathChanged)
    Q_PROPERTY(QString rawContent READ rawContent WRITE setRawContent NOTIFY rawContentChanged)
    Q_PROPERTY(bool modified READ modified NOTIFY modifiedChanged)
    Q_PROPERTY(QString encoding READ encoding NOTIFY encodingChanged)

public:
    struct BlockSegment {
        QString id;
        QString name;
        QString content;
        int startPos;
        int endPos;
    };

    explicit MdDocument(QObject *parent = nullptr);

    void load(const QString &filePath);
    Q_INVOKABLE void save();
    Q_INVOKABLE void reload();

    QString filePath() const;
    QString rawContent() const;
    void setRawContent(const QString &content);
    bool modified() const;
    QString encoding() const;

    QList<BlockSegment> blocks() const;
    Q_INVOKABLE QVariantList blockList() const;
    Q_INVOKABLE void wrapSelectionAsBlock(int startPos, int endPos,
                                           const QString &blockId, const QString &blockName);
    Q_INVOKABLE void insertBlock(int position, const QString &blockId,
                                  const QString &blockName, const QString &content);

    Q_INVOKABLE void clear();

signals:
    void filePathChanged();
    void rawContentChanged();
    void modifiedChanged();
    void saved();
    void loadFailed(const QString &error);
    void saveFailed(const QString &error);
    void encodingChanged();

private:
    void parseBlocks();

    QString m_filePath;
    QString m_rawContent;
    QString m_savedContent;
    bool m_modified = false;
    QString m_encoding = QStringLiteral("UTF-8");
    QStringConverter::Encoding m_streamEncoding = QStringConverter::Utf8;
    bool m_hasBom = false;
    QList<BlockSegment> m_blocks;
};

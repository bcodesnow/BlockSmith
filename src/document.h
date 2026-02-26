#pragma once

#include <QObject>
#include <QString>
#include <QList>
#include <QVariantList>
#include <QStringConverter>
#include <QFileSystemWatcher>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

class BlockStore;

class Document : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Use via AppController.currentDocument")

    Q_PROPERTY(QString filePath READ filePath NOTIFY filePathChanged)
    Q_PROPERTY(QString rawContent READ rawContent WRITE setRawContent NOTIFY rawContentChanged)
    Q_PROPERTY(bool modified READ modified NOTIFY modifiedChanged)
    Q_PROPERTY(QString encoding READ encoding NOTIFY encodingChanged)
    Q_PROPERTY(FileType fileType READ fileType NOTIFY filePathChanged)
    Q_PROPERTY(QString formatId READ formatId NOTIFY filePathChanged)
    Q_PROPERTY(SyntaxMode syntaxMode READ syntaxMode NOTIFY filePathChanged)
    Q_PROPERTY(ToolbarKind toolbarKind READ toolbarKind NOTIFY filePathChanged)
    Q_PROPERTY(PreviewKind previewKind READ previewKind NOTIFY filePathChanged)
    Q_PROPERTY(bool isJson READ isJson NOTIFY filePathChanged)
    Q_PROPERTY(bool supportsPreview READ supportsPreview NOTIFY filePathChanged)

public:
    enum FileType { Markdown, Json, Yaml, PlainText };
    Q_ENUM(FileType)
    enum SyntaxMode { SyntaxPlainText, SyntaxMarkdown, SyntaxJson, SyntaxYaml };
    Q_ENUM(SyntaxMode)
    enum ToolbarKind { ToolbarNone, ToolbarMarkdown, ToolbarJson, ToolbarYaml };
    Q_ENUM(ToolbarKind)
    enum PreviewKind { PreviewNone, PreviewMarkdown };
    Q_ENUM(PreviewKind)

    struct BlockSegment {
        QString id;
        QString name;
        QString content;
        int startPos;
        int endPos;
    };

    explicit Document(QObject *parent = nullptr);

    void load(const QString &filePath);
    Q_INVOKABLE void save();
    void saveTo(const QString &newPath);
    Q_INVOKABLE void reload();

    QString filePath() const;
    FileType fileType() const;
    QString formatId() const;
    SyntaxMode syntaxMode() const;
    ToolbarKind toolbarKind() const;
    PreviewKind previewKind() const;
    bool isJson() const;
    bool supportsPreview() const;

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

    Q_INVOKABLE QVariantList findMatches(const QString &text, bool caseSensitive) const;
    Q_INVOKABLE QVariantList computeBlockRanges() const;
    Q_INVOKABLE QString prettifyJson() const;
    Q_INVOKABLE QString prettifyYaml() const;
    void setBlockStore(BlockStore *store);

    void setAutoSave(bool enabled, int intervalSecs);

signals:
    void filePathChanged();
    void rawContentChanged();
    void modifiedChanged();
    void saved();
    void loadFailed(const QString &error);
    void saveFailed(const QString &error);
    void encodingChanged();
    void fileChangedExternally();
    void fileDeletedExternally();
    void autoSaved();

private slots:
    void onFileChanged(const QString &path);
    void onAutoSaveTimer();

private:
    void parseBlocks();
    void watchFile(const QString &path);
    void unwatchFile();

    QString m_filePath;
    QString m_rawContent;
    QString m_savedContent;
    bool m_modified = false;
    QString m_encoding = QStringLiteral("UTF-8");
    QStringConverter::Encoding m_streamEncoding = QStringConverter::Utf8;
    bool m_hasBom = false;
    QList<BlockSegment> m_blocks;

    QFileSystemWatcher m_watcher;
    bool m_ignoreNextChange = false; // suppress watcher after our own save

    QTimer m_autoSaveTimer;
    BlockStore *m_blockStore = nullptr;
};

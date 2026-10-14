package app.meuvercel.android

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import kotlin.concurrent.thread

/** Android SAF access without broad storage permissions or persistent URI grants. */
class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "app.meuvercel.android/site_folder"
        private const val PICK_SITE_FOLDER = 7191
        private const val MAX_FILES = 120
        private const val MAX_BYTES = 20 * 1024 * 1024
    }

    private var pendingPicker: MethodChannel.Result? = null
    private val authorizedFiles = mutableMapOf<String, Uri>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickFolder" -> {
                    if (pendingPicker != null) {
                        result.error("busy", "Seletor já aberto", null)
                    } else {
                        authorizedFiles.clear()
                        pendingPicker = result
                        try {
                            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            startActivityForResult(intent, PICK_SITE_FOLDER)
                        } catch (_: Exception) {
                            pendingPicker = null
                            result.error("picker", "Não foi possível abrir o seletor", null)
                        }
                    }
                }
                "readFile" -> {
                    val uri = authorizedFiles[call.arguments as? String]
                    if (uri == null) {
                        result.error("permission", "Arquivo fora da pasta autorizada", null)
                    } else {
                        thread(name = "site-file-read") {
                            try {
                                val output = ByteArrayOutputStream()
                                contentResolver.openInputStream(uri)?.use { input ->
                                    val buffer = ByteArray(32768)
                                    var n = input.read(buffer)
                                    while (n >= 0) {
                                        if (n > 0) {
                                            if (output.size() > MAX_BYTES - n) {
                                                throw IllegalArgumentException("Arquivo excede 20 MiB")
                                            }
                                            output.write(buffer, 0, n)
                                        }
                                        n = input.read(buffer)
                                    }
                                } ?: throw IllegalArgumentException("Arquivo inacessível")
                                val bytes = output.toByteArray()
                                runOnUiThread { result.success(bytes) }
                            } catch (_: Exception) {
                                runOnUiThread { result.error("read", "Falha ao ler arquivo selecionado", null) }
                            }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    @Deprecated("Android Activity callback required by SAF picker")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_SITE_FOLDER) return
        val pending = pendingPicker ?: return
        pendingPicker = null
        val treeUri = data?.data
        if (resultCode != Activity.RESULT_OK || treeUri == null) {
            pending.success(null)
            return
        }
        thread(name = "site-folder-list") {
            try {
                val (items, paths) = listFiles(treeUri)
                runOnUiThread {
                    authorizedFiles.clear()
                    authorizedFiles.putAll(paths)
                    pending.success(items)
                }
            } catch (_: Exception) {
                runOnUiThread {
                    authorizedFiles.clear()
                    pending.error("tree", "Pasta indisponível, protegida ou muito grande", null)
                }
            }
        }
    }

    private fun listFiles(tree: Uri): Pair<List<Map<String, Any>>, Map<String, Uri>> {
        val found = mutableListOf<Map<String, Any>>()
        val paths = mutableMapOf<String, Uri>()
        val rootId = DocumentsContract.getTreeDocumentId(tree)
        var totalBytes = 0L
        var visited = 0
        fun walk(parentId: String, prefix: String, depth: Int) {
            if (depth > 12) throw IllegalArgumentException("Pasta muito profunda")
            val children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, parentId)
            val projection = arrayOf(
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                DocumentsContract.Document.COLUMN_MIME_TYPE,
                DocumentsContract.Document.COLUMN_SIZE,
            )
            val entries = mutableListOf<Triple<String, String, Pair<String, Long>>>()
            contentResolver.query(children, projection, null, null, null)?.use { cursor ->
                val idCol = cursor.getColumnIndexOrThrow(projection[0])
                val nameCol = cursor.getColumnIndexOrThrow(projection[1])
                val typeCol = cursor.getColumnIndexOrThrow(projection[2])
                val sizeCol = cursor.getColumnIndex(projection[3])
                while (cursor.moveToNext()) {
                    visited++
                    if (visited > 300) throw IllegalArgumentException("Muitos itens")
                    val id = cursor.getString(idCol) ?: throw IllegalArgumentException("ID inválido")
                    val name = cursor.getString(nameCol) ?: throw IllegalArgumentException("Nome inválido")
                    val mime = cursor.getString(typeCol) ?: ""
                    val size = if (sizeCol < 0 || cursor.isNull(sizeCol)) -1L else cursor.getLong(sizeCol)
                    if (name.isEmpty() || name == "." || name == ".." || name.contains('/') || name.contains('\\')) {
                        throw IllegalArgumentException("Nome inválido")
                    }
                    entries.add(Triple(id, name, Pair(mime, size)))
                }
            } ?: throw IllegalArgumentException("Pasta não pode ser listada")
            for ((id, name, meta) in entries) {
                val relative = prefix + name
                if (meta.first == DocumentsContract.Document.MIME_TYPE_DIR) {
                    walk(id, "$relative/", depth + 1)
                } else {
                    if (found.size >= MAX_FILES) throw IllegalArgumentException("Mais de 120 arquivos")
                    // Size unknown is checked during readFile and in Dart.
                    val size = meta.second
                    if (size < -1 || size > MAX_BYTES) throw IllegalArgumentException("Arquivo grande")
                    if (size >= 0) {
                        totalBytes += size
                        if (totalBytes > MAX_BYTES) throw IllegalArgumentException("Pasta grande")
                    }
                    val documentUri = DocumentsContract.buildDocumentUriUsingTree(tree, id)
                    val encoded = documentUri.toString()
                    paths[encoded] = documentUri
                    found.add(mapOf("path" to relative, "uri" to encoded, "size" to size))
                }
            }
        }
        walk(rootId, "", 0)
        return Pair(found, paths)
    }
}

/*
 * Preloaded into azurite (NODE_OPTIONS=--require ...). Persists the table service
 * as one paged file set per table (__azurite_db_table__.json.<n>.<page>) instead of
 * a single JSON blob, so no file nears Node's string cap and an autosave rewrites
 * only the tables that changed. A legacy single-file db loads as-is and is split
 * on the first save.
 */
const Loki = require(require.resolve('lokijs', { paths: ['/opt/azurite'] }))

const TABLE_DB = '__azurite_db_table__.json'

function createAdapter() {
  const fsAdapter = new Loki.LokiFsAdapter()
  const adapter = new Loki.LokiPartitioningAdapter(
    {
      // A page missing on disk (crash between writes) loads as an empty table instead of throwing.
      loadDatabase: (name, cb) => fsAdapter.loadDatabase(name, (r) => cb(r || (/\.\d+\.\d+$/.test(name) ? '' : r))),
      saveDatabase: (name, data, cb) => fsAdapter.saveDatabase(name, data, cb),
    },
    { paging: true }
  )

  // Partitions are positional: the first save rewrites every table, and dropping a
  // table rewrites every table after it.
  let saved
  const exportDatabase = adapter.exportDatabase
  adapter.exportDatabase = function (dbname, dbref, cb) {
    const names = dbref.collections.map((c) => c.name)
    const from = saved ? names.findIndex((n, i) => n !== saved[i]) : 0
    if (from !== -1) dbref.collections.slice(from).forEach((c) => (c.dirty = true))
    exportDatabase.call(this, dbname, dbref, (err) => {
      if (!err) saved = names
      cb(err)
    })
  }
  return adapter
}

const configureOptions = Loki.prototype.configureOptions
Loki.prototype.configureOptions = function (options, initialConfig) {
  if (initialConfig && options?.persistenceMethod === 'fs' && this.filename.endsWith(TABLE_DB)) {
    options = { ...options, adapter: createAdapter() }
  }
  return configureOptions.call(this, options, initialConfig)
}

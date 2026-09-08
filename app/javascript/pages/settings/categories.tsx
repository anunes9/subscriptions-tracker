import { Head, router, useForm } from '@inertiajs/react'
import { type FormEvent, useState } from 'react'
import AppLayout from '@/components/app_layout'

type Category = {
  id: string
  name: string
  icon: string | null
  color: string | null
  is_preset: boolean
}

type CategoriesPageProps = {
  categories: Category[]
  errors?: Record<string, string[]>
}

const DEFAULT_COLOR = '#6b7280'

export default function Categories({ categories, errors }: CategoriesPageProps) {
  const presets = categories.filter((category) => category.is_preset)
  const custom = categories.filter((category) => !category.is_preset)

  const [editingId, setEditingId] = useState<string | null>(null)
  const form = useForm({ name: '', icon: '', color: DEFAULT_COLOR })

  const startEditing = (category: Category) => {
    setEditingId(category.id)
    form.setData({ name: category.name, icon: category.icon ?? '', color: category.color ?? DEFAULT_COLOR })
  }

  const cancelEditing = () => {
    setEditingId(null)
    form.reset()
  }

  const submit = (e: FormEvent) => {
    e.preventDefault()
    form.transform((data) => ({ category: data }))

    if (editingId) {
      form.patch(`/categories/${editingId}`, { onSuccess: cancelEditing })
    } else {
      form.post('/categories', { onSuccess: () => form.reset() })
    }
  }

  const deleteCategory = (category: Category) => {
    if (window.confirm(`Delete "${category.name}"? Its subscriptions will move to Other.`)) {
      router.delete(`/categories/${category.id}`)
    }
  }

  return (
    <AppLayout title="Categories">
      <Head title="Categories" />

      <section>
        <h2 className="text-xs font-semibold uppercase tracking-wide text-slate-500">Presets</h2>
        <ul className="mt-3 flex flex-wrap gap-2">
          {presets.map((category) => (
            <li
              key={category.id}
              className="flex items-center gap-2 rounded-full border border-slate-200 bg-white px-3 py-1.5 text-sm text-slate-700"
            >
              <span className="h-2 w-2 rounded-full" style={{ backgroundColor: category.color ?? DEFAULT_COLOR }} />
              {category.name}
            </li>
          ))}
        </ul>
      </section>

      <section className="mt-8">
        <h2 className="text-xs font-semibold uppercase tracking-wide text-slate-500">Your categories</h2>

        {custom.length === 0 ? (
          <p className="mt-3 text-sm text-slate-500">You haven&rsquo;t added any custom categories yet.</p>
        ) : (
          <ul className="mt-3 divide-y divide-slate-200 rounded-md border border-slate-200 bg-white">
            {custom.map((category) => (
              <li key={category.id} className="flex items-center justify-between px-4 py-3">
                <div className="flex items-center gap-2 text-sm text-slate-900">
                  <span className="h-2 w-2 rounded-full" style={{ backgroundColor: category.color ?? DEFAULT_COLOR }} />
                  {category.name}
                </div>
                <div className="flex items-center gap-3 text-sm font-medium">
                  <button
                    type="button"
                    onClick={() => startEditing(category)}
                    className="text-slate-600 hover:text-slate-900"
                  >
                    Edit
                  </button>
                  <button
                    type="button"
                    onClick={() => deleteCategory(category)}
                    className="text-red-600 hover:text-red-700"
                  >
                    Delete
                  </button>
                </div>
              </li>
            ))}
          </ul>
        )}
      </section>

      <section className="mt-8 max-w-sm">
        <h2 className="text-xs font-semibold uppercase tracking-wide text-slate-500">
          {editingId ? 'Edit category' : 'Add a category'}
        </h2>
        <form onSubmit={submit} className="mt-3 space-y-3">
          <div>
            <input
              type="text"
              placeholder="Name"
              value={form.data.name}
              onChange={(e) => form.setData('name', e.target.value)}
              className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm text-slate-900 placeholder:text-slate-400 focus:border-slate-900 focus:outline-none focus:ring-1 focus:ring-slate-900"
            />
            {errors?.name && <p className="mt-1 text-sm text-red-600">Name {errors.name[0]}</p>}
          </div>

          <div className="flex items-center gap-3">
            <label className="text-sm text-slate-600" htmlFor="color">
              Color
            </label>
            <input
              id="color"
              type="color"
              value={form.data.color}
              onChange={(e) => form.setData('color', e.target.value)}
              className="h-8 w-14 cursor-pointer rounded border border-slate-300"
            />
          </div>

          <div className="flex items-center gap-3">
            <button
              type="submit"
              disabled={form.processing}
              className="rounded-md bg-slate-900 px-4 py-2 text-sm font-semibold text-white transition hover:bg-slate-800 disabled:opacity-60"
            >
              {editingId ? 'Save changes' : 'Add category'}
            </button>
            {editingId && (
              <button
                type="button"
                onClick={cancelEditing}
                className="text-sm font-medium text-slate-500 hover:text-slate-700"
              >
                Cancel
              </button>
            )}
          </div>
        </form>
      </section>
    </AppLayout>
  )
}

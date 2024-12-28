/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './_includes/**/*.html',
    './_includes/**/*.html.liquid',
    './_layouts/**/*.html',
    './_layouts/**/*.html.liquid',
    './_games/*.md',
    './*.md',
    './*.html',
    './*.html.liquid'
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}


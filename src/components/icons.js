import { h } from 'vue'

function icon(children) {
  return {
    props: {
      size: { type: [Number, String], default: 20 },
      strokeWidth: { type: [Number, String], default: 2 },
    },
    setup(props) {
      return () =>
        h(
          'svg',
          {
            xmlns: 'http://www.w3.org/2000/svg',
            width: props.size,
            height: props.size,
            viewBox: '0 0 24 24',
            fill: 'none',
            stroke: 'currentColor',
            'stroke-width': props.strokeWidth,
            'stroke-linecap': 'round',
            'stroke-linejoin': 'round',
          },
          children.map((child) => {
            if (typeof child === 'string') return h('path', { d: child })
            return h(child[0], child[1])
          })
        )
    },
  }
}

export const Flame = icon([
  'M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 0 0 2.5 2.5z',
])

export const LayoutDashboard = icon([
  ['rect', { width: '7', height: '9', x: '3', y: '3', rx: '1' }],
  ['rect', { width: '7', height: '5', x: '14', y: '3', rx: '1' }],
  ['rect', { width: '7', height: '9', x: '14', y: '12', rx: '1' }],
  ['rect', { width: '7', height: '5', x: '3', y: '16', rx: '1' }],
])

export const MapPin = icon([
  ['path', { d: 'M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0' }],
  ['circle', { cx: '12', cy: '10', r: '3' }],
])

export const UserCheck = icon([
  ['path', { d: 'M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2' }],
  ['circle', { cx: '9', cy: '7', r: '4' }],
  ['polyline', { points: '16 11 18 13 22 9' }],
])

export const Users = icon([
  ['path', { d: 'M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2' }],
  ['circle', { cx: '9', cy: '7', r: '4' }],
  ['path', { d: 'M22 21v-2a4 4 0 0 0-3-3.87' }],
  ['path', { d: 'M16 3.13a4 4 0 0 1 0 7.75' }],
])

export const Shield = icon([
  'M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z',
])

export const Truck = icon([
  ['path', { d: 'M14 18V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v11a1 1 0 0 0 1 1h2' }],
  ['path', { d: 'M15 18H9' }],
  ['path', { d: 'M19 18h2a1 1 0 0 0 1-1v-3.65a1 1 0 0 0-.22-.624l-3.48-4.35A1 1 0 0 0 17.52 8H14' }],
  ['circle', { cx: '17', cy: '18', r: '2' }],
  ['circle', { cx: '7', cy: '18', r: '2' }],
])

export const FileText = icon([
  ['path', { d: 'M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z' }],
  ['path', { d: 'M14 2v4a2 2 0 0 0 2 2h4' }],
  ['path', { d: 'M10 9H8' }],
  ['path', { d: 'M16 13H8' }],
  ['path', { d: 'M16 17H8' }],
])

export const Inbox = icon([
  ['polyline', { points: '22 12 16 12 14 15 10 15 8 12 2 12' }],
  ['path', { d: 'M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z' }],
])

export const ClipboardList = icon([
  ['rect', { width: '8', height: '4', x: '8', y: '2', rx: '1', ry: '1' }],
  ['path', { d: 'M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2' }],
  ['path', { d: 'M12 11h4' }],
  ['path', { d: 'M12 16h4' }],
  ['path', { d: 'M8 11h.01' }],
  ['path', { d: 'M8 16h.01' }],
])

export const PackageCheck = icon([
  ['path', { d: 'm16 16 2 2 4-4' }],
  ['path', { d: 'M21 10V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l2-1.14' }],
  ['path', { d: 'm7.5 4.27 9 5.15' }],
  ['polyline', { points: '3.29 7 12 12 20.71 7' }],
  ['line', { x1: '12', x2: '12', y1: '22', y2: '12' }],
])

export const History = icon([
  ['path', { d: 'M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8' }],
  ['path', { d: 'M3 3v5h5' }],
  ['path', { d: 'M12 7v5l4 2' }],
])

export const Menu = icon([
  ['line', { x1: '4', x2: '20', y1: '12', y2: '12' }],
  ['line', { x1: '4', x2: '20', y1: '6', y2: '6' }],
  ['line', { x1: '4', x2: '20', y1: '18', y2: '18' }],
])

export const LogOut = icon([
  ['path', { d: 'M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4' }],
  ['polyline', { points: '16 17 21 12 16 7' }],
  ['line', { x1: '21', x2: '9', y1: '12', y2: '12' }],
])

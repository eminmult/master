const ICON_NAMES: Record<string, string> = {
  order_created: 'add_circle',
  order_accepted: 'check_circle',
  order_assigned: 'assignment_ind',
  master_on_the_way: 'directions_car',
  master_arrived: 'flag',
  work_started: 'construction',
  order_completed: 'task_alt',
  order_canceled: 'cancel',
  new_message: 'chat',
  new_review: 'star',
  new_order_available: 'notification_important',
}

export function useNotificationIcon() {
  function iconName(type: string): string {
    return ICON_NAMES[type] || 'notifications'
  }
  function iconClass(type: string): string {
    if (type === 'order_canceled') return 'icon-danger'
    if (['order_completed', 'order_accepted'].includes(type)) return 'icon-success'
    if (['new_order_available', 'order_assigned'].includes(type)) return 'icon-primary'
    if (type === 'new_message') return 'icon-info'
    return ''
  }
  return { iconName, iconClass }
}

# --------------------------------
# Event seeds
# --------------------------------
EVENTS = %w(TAB_CREATED TAB_REMOVED TAB_ACTIVATED TAB_MOVED TAB_UPDATED TAB_ATTACHED TAB_DETACHED)
EVENT_DESCS = [ 'New tab was opened', 'Tab was closed', 'Tab was focused', 'Tab was moved within window',
                'Tab was updated (ie. new url inserted)', 'Tab was moved between windows (docked to new)',
                'Tab was moved between windows (detached from old)' ]

# Clear events table
if Event.count != EVENTS.size
  Event.delete_all
  ActiveRecord::Base.connection.reset_pk_sequence!(Event.table_name)
  EVENTS.each_with_index do |event, index|
    Event.create!(name: event, desc: EVENT_DESCS[index])
  end
end

# --------------------------------
# Advice seeds
# --------------------------------
ADVICES = %w(TAB_DOMAIN_SORT TAB_DOMAIN_SORT_V2 TAB_DOMAIN_SORT_V3)
ADVICE_DESCS = [
  'Will sort all opened tabs in current window by domain URLs',
  'Will wait some time after execution and dont trigger again.',
  'Will also check if focues tabs are not next to each other and will use running average instead of exact max_gap time.'
]

if Advice.count != ADVICES.size
  Advice.delete_all
  ActiveRecord::Base.connection.reset_pk_sequence!(Advice.table_name)
  ADVICES.each_with_index do |advice, index|
    Advice.create!(name: advice, desc: ADVICE_DESCS[index])
  end
end

# --------------------------------
# Pattern seeds
# --------------------------------
PATTERN_SEQUENCES = [
  'TAB_ACTIVATED TAB_ACTIVATED TAB_ACTIVATED TAB_ACTIVATED',
  'TAB_ACTIVATED TAB_ACTIVATED TAB_ACTIVATED TAB_ACTIVATED',
  'TAB_ACTIVATED TAB_ACTIVATED TAB_ACTIVATED TAB_ACTIVATED'
]
PATTERN_NAMES = [ 'MULTI_ACTIVATE', 'MULTI_ACTIVATE_V2', 'MULTI_ACTIVATE_V3' ]
PATTERN_ADVICE_IDS = [ Advice.find_by(name: 'TAB_DOMAIN_SORT').id, Advice.find_by(name: 'TAB_DOMAIN_SORT_V2').id, Advice.find_by(name: 'TAB_DOMAIN_SORT_V3').id]
PATTERN_DESCS = [
  'User focused four tabs in a constant time gap.',
  'User focused four tabs in a constant time gap (excluding some time after accepting).',
  'User focused four tabs (excluding tabs next to each other) in his running average time gap.'
]

if Pattern.count != PATTERN_SEQUENCES.size
  Pattern.delete_all
  ActiveRecord::Base.connection.reset_pk_sequence!(Pattern.table_name)
  PATTERN_SEQUENCES.each_with_index do |seq, index|
    Pattern.create!(sequence: seq, name: PATTERN_NAMES[index], desc: PATTERN_DESCS[index], advice_id: PATTERN_ADVICE_IDS[index])
  end
end

# --------------------------------
# Resolution seeds
# --------------------------------

RESOLUTIONS = %w(ACCEPTED REJECTED REVERTED AUTOMATIC)
RESOLUTION_DESCS = [ 'User manually accepted recommendation', 'User manually rejected recommendation',
                    'User accepted but later reverted recommendation', 'Recommendation was automatically accepted' ]

if Resolution.count != RESOLUTIONS.size
  Resolution.delete_all
  ActiveRecord::Base.connection.reset_pk_sequence!(Resolution.table_name)
  RESOLUTIONS.each_with_index do |resolution, index|
    Resolution.create!(name: resolution, desc: RESOLUTION_DESCS[index])
  end
end

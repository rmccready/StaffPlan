class window.StaffPlan.Collections.WorkWeeks extends Backbone.Collection
  WEEK_IN_MILLISECONDS: 7 * 24 * 3600 * 1000
  
  model: StaffPlan.Models.WorkWeek
  
  initialize: (models, options) ->
    _.extend @, options

  dateRangeMeta: ->
    @parent.dateRangeMeta()
  
  url: ->
    @parent.url() + "/work_weeks"
  
  between: (begin, end) ->
    weeks = _.map _.range(begin, end, @WEEK_IN_MILLISECONDS), (timestamp) =>
      d = new XDate(timestamp)
      week = @detect (week) =>
        week.get("year") is d.getFullYear() and
          week.get("cweek") is d.getWeek()
      week or new StaffPlan.Models.WorkWeek
        cweek: d.getWeek()
        year: d.getFullYear()
        actual_hours: 0
        estimated_hours: 0
        proposed: false
    new StaffPlan.Collections.WorkWeeks weeks,
      parent: @parent
   
  comparator: (first, second) ->
    firstYear = first.get('year')
    secondYear = second.get('year')
    
    if firstYear == secondYear
      if first.get('cweek') < second.get('cweek') then -1 else 1
    else
      if firstYear < secondYear then -1 else 1

class window.StaffPlan.Views.StaffPlans.Index extends Support.CompositeView
  className: "list padding-top-120"
  events:
    "click div.date-paginator a.pagination": "paginate"
    "click ul.dropdown-menu.sort-users li a": "sortUsers"
    "click button.btn-primary[data-filter]": "toggleFilter"
  
  
  toggleFilter: (event) ->
    filter = localStorage.getItem("staffplanFilter")
    models = if filter is "inactive" then StaffPlan.users.active() else StaffPlan.users.inactive()
    localStorage.setItem("staffplanFilter", if filter is "active" then "inactive" else "active")
    @users.reset models

  sortUsers: (event) ->
    event.stopPropagation()
    event.preventDefault()
    target = $(event.target)
    [criterion, order] = [target.data('criterion'), target.data('order')]
    sorted = switch criterion
      when "workload"
        @users.sortBy (user) -> user.workload()
      when "name"
        @users.sortBy (user) -> user.get("last_name")
    @users.reset (if order is "asc" then sorted else sorted.reverse())

  leave: ->
    @off()
    @remove()

  paginate: (event) ->
    event.preventDefault()
    event.stopPropagation()

  initialize: ->
    @debouncedRender = _.debounce(@render, 500)
    $(window).bind "resize", (event) =>
      @debouncedRender()
    localStorage.setItem("staffplanFilter", "active")
    @users = new StaffPlan.Collections.Users @options.users.active()
    m = moment()
    @startDate = m.utc().startOf('day').subtract('days', m.day() - 1).subtract('weeks', 1)
    
    @users.bind "reset", (event) =>
      @render()

    # Event bindings
    @on "date:changed", (message) =>
      if message.action is "previous"
        @startDate.subtract('weeks', @numberOfBars)
      else
        @startDate.add('weeks', @numberOfBars)
      @children.each (child) =>
        child.trigger "date:changed"
          begin: @startDate
          count: @numberOfBars
    
    @on "membership:disable", (message) =>
      user = @users.detect (user) -> user.id is message.userId
      user.membership.save
        disabled: not user.membership.get("disabled")
      , success: (model, response) =>
          $(message.subview.el).slideUp 400, "linear", () ->
            $(@).remove()
      , error: (model, response) ->
          alert "FAIL"
    @on "year:changed", (message) =>
      @render()
    @on "membership:archive", (message) =>
      user = @users.detect (user) -> user.id is message.userId
      user.membership.save
        archived: not user.membership.get("archived")
      , success: (model, response) =>
          $(message.subview.el).slideUp 400, "linear", () ->
            $(@).remove()
      , error: (model, response) ->
          alert "FAIL"
  render: ->
    @$el.html StaffPlan.Templates.StaffPlans.index.pagination
    buttonText = if localStorage.getItem("staffplanFilter") is "active"
      "Show inactive"
    else
      "Show active"
    @$el.find("button.btn-primary").text(buttonText)
    if StaffPlan.relevantYears.length > 2
      @yearFilter = new StaffPlan.Views.Shared.YearFilter
        years: StaffPlan.relevantYears
        parent: @
      @$el.find('div.date-paginator div.fixed-180').append @yearFilter.render().el
    @users.each (user) =>
      view = new StaffPlan.Views.StaffPlans.ListItem
        model: user
        parent: @
        startDate: @startDate.valueOf()
      @appendChild view
    @$el.append StaffPlan.Templates.StaffPlans.index.addStaff
    
    chartContainerWidth = Math.round(($("body").width() - 2 * 40) * 10 / 12)
    @numberOfBars = Math.round(chartContainerWidth / 40) - 2
    
    
    dateRangeView = new StaffPlan.Views.DateRangeView
      collection: _.range(@startDate.valueOf(), @startDate.valueOf() + @numberOfBars * 7 * 86400 * 1000, 7 * 86400 * 1000)
    @renderChildInto dateRangeView, @$el.find("#date-target")


    @

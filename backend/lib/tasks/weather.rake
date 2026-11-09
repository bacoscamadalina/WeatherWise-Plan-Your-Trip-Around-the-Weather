namespace :weather do
  desc "Enqueue forecast refreshes for recently popular locations"
  task refresh_popular: :environment do
    RefreshPopularForecastsJob.perform_later
    puts "Popular forecast refresh scan enqueued."
  end
end

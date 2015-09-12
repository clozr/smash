recipe start
  for service in services
    if service['start']
      + service {{service.name}} start

recipe poll
  for service in services
    if service['start']
      + service {{service.name}} status

recipe stop
  for service in services
    if service['start']
      +& service {{service.name}} stop



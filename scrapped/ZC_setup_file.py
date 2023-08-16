import os

zic_dir=os.getcwd()
tmp_dir="%s/tmp/merged" % zic_dir


def WriteSetupFile(zic_input_file):
  """Writes the list of zones that ZoneCompactor should process."""
  links = []
  zones = []
  for line in open(zic_input_file):
    fields = line.split()
    if fields:
      line_type = fields[0]
      if line_type == 'Link':
        # Each "Link" line requires the creation of a link from an old tz ID to
        # a new tz ID, and implies the existence of a zone with the old tz ID.
        #
        # IANA terminology:
        # TARGET = the new tz ID, LINK-NAME = the old tz ID
        target = fields[1]
        link_name = fields[2]
        links.append('Link %s %s' % (target, link_name))
        zones.append('Zone %s' % link_name)
      elif line_type == 'Zone':
        # Each "Zone" line indicates the existence of a tz ID.
        #
        # IANA terminology:
        # NAME is the tz ID, other fields like STDOFF, RULES, FORMAT,[UNTIL] are
        # ignored.
        name = fields[1]
        zones.append('Zone %s' % name)

  zone_compactor_setup_file = '%s/tmp/setup' % zic_dir
  setup = open(zone_compactor_setup_file, 'w')

  # Ordering requirement from ZoneCompactor: Links must come first.
  for link in sorted(set(links)):
    setup.write('%s\n' % link)
  for zone in sorted(set(zones)):
    setup.write('%s\n' % zone)
  setup.close()
  return zone_compactor_setup_file

WriteSetupFile("%s/rearguard.zi" % tmp_dir)
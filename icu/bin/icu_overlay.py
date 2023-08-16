import os,sys
import glob
import shutil
import subprocess


current_dir=os.path.dirname(os.path.realpath(__file__))
timezone_output_data_dir= '%s/out' % current_dir
if not os.path.exists(timezone_output_data_dir):
    os.mkdir(timezone_output_data_dir)
tmp_dir = '%s/tmp' % current_dir
if not os.path.exists(tmp_dir):
    os.mkdir(tmp_dir)
icu_build_dir = '%s/icu' % tmp_dir
if not os.path.exists(icu_build_dir):
    os.mkdir(icu_build_dir)
icu_overlay_dir = '%s/icu_overlay' % timezone_output_data_dir
if not os.path.exists(icu_overlay_dir):
    os.mkdir(icu_overlay_dir)
icu_overlay_dat_file = '%s/icu_tzdata.dat' % icu_overlay_dir


def datFile(icu_build_dir):
  """Returns the location of the ICU .dat file in the specified ICU build dir."""
  dat_file_pattern = '%s/icudt??l.dat' % timezone_output_data_dir
  dat_files = glob.glob(dat_file_pattern)
  if len(dat_files) != 1:
    print('ERROR: Unexpectedly found %d .dat files (%s). Halting.' % (len(dat_files), dat_files))
    sys.exit(1)
  dat_file = dat_files[0]
  return dat_file


def MakeAndCopyOverlayTzIcuData(icu_build_dir, dest_file):
  """Makes a .dat file containing just time-zone data.

  The overlay file can be used as an overlay of a full ICU .dat file
  to provide newer time zone data. Some strings like translated
  time zone names will be missing, but rules will be correct.
  """

  # Keep track of the original cwd so we can go back to it at the end.
  original_working_dir = os.getcwd()

  # Regenerate the .res files.
  os.chdir(icu_build_dir)
  #subprocess.check_call(['make', '-j32'])

  # The list of ICU resources needed for time zone data overlays.
  tz_res_names = [
          'metaZones.res',
          'timezoneTypes.res',
          'windowsZones.res',
          'zoneinfo64.res',
  ]

  dat_file = datFile(icu_build_dir)
  icu_package_dat = os.path.basename(dat_file)
  if not icu_package_dat.endswith('.dat'):
      print('%s does not end with .dat' % icu_package_dat)
      sys.exit(1)
  icu_package = icu_package_dat[:-4]

  # Create a staging directory to hold the files to go into the overlay .dat
  res_staging_dir = '%s/overlay_res' % icu_build_dir

  # Create a .lst file to pass to pkgdata.
  tz_files_file = '%s/tzdata.lst' % res_staging_dir
  with open(tz_files_file, "a") as tz_files:
    for tz_res_name in tz_res_names:
      tz_files.write('%s\n' % tz_res_name)

  icu_lib_dir = '%s/lib' % icu_build_dir
  pkg_data_bin = '%s/bin/pkgdata' % icu_build_dir

  # Run pkgdata to create a .dat file.
  icu_env = os.environ.copy()
  icu_env["LD_LIBRARY_PATH"] = icu_lib_dir

  # pkgdata treats the .lst file it is given as relative to CWD, and the path also affects the
  # resource names in the .dat file produced so we change the CWD.
  os.chdir(res_staging_dir)

  # -F : force rebuilding all data
  # -m common : create a .dat
  # -v : verbose
  # -T . : use "." as a temp dir
  # -d . : use "." as the dest dir
  # -p <name> : Set the "data name"
  p = subprocess.Popen(
      [pkg_data_bin, '-F', '-m', 'common', '-v', '-T', '.', '-d', '.', '-p',
          icu_package, tz_files_file],
      env=icu_env)
  p.wait()
  if p.returncode != 0:
    print('pkgdata failed with status code: %s' % p.returncode)

  # Copy the .dat to the chosen place / name.
  generated_dat_file = '%s/%s' % (res_staging_dir, icu_package_dat)
  shutil.copyfile(generated_dat_file, dest_file)
  print('ICU overlay .dat can be found here: %s' % dest_file)

  # Switch back to the original working cwd.
  os.chdir(original_working_dir)


#main
MakeAndCopyOverlayTzIcuData(icu_build_dir, icu_overlay_dat_file)
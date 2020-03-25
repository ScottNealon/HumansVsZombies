import argparse
import os

def valid_dev_dir(dev_dir):
    if not os.path.isdir(dev_dir) or not os.access(dev_dir, os.R_OK):
        raise argparse.ArgumentTypeError("Directory provided is not readable")

    
    # code section check
    code_subdir = os.path.join(dev_dir, 'code/')
    if not os.path.isdir(code_subdir) or not os.access(code_subdir, os.R_OK) or not os.path.exists(os.path.join(code_subdir, 'breeds.nls')):
        raise argparse.ArgumentTypeError("Code not provided. Directory requires a code subdirectory containing a breeds.nls file and any procedural code stored in other .nls files")

    # info section check
    info_md_file = os.path.join(dev_dir, "info.md")
    if not os.path.exists(info_md_file) or not os.access(info_md_file, os.R_OK):
        raise argparse.ArgumentTypeError("Directory does not have a readable info.md file present to provide content for the Info tab of the NetLogo file.")

    # netlogo version section check
    netlogo_version_file = os.path.join(dev_dir, "netlogo_version.txt")
    if not os.path.exists(netlogo_version_file) or not os.access(netlogo_version_file, os.R_OK):
        raise argparse.ArgumentTypeError("Directory does not have a readable netlogo_version.txt file present at subpath netlogo_version.txt to specify the version of NetLogo being used.")

    # model settings check
    model_settings_file = os.path.join(dev_dir, "model_settings.txt")
    if not os.path.exists(model_settings_file) or not os.access(model_settings_file, os.R_OK):
        raise argparse.ArgumentTypeError("Directory does not have a readable model_settings.txt file present at subpath model_settings.txt to specify whether snap to grid is enabled.")

    # link shapes check
    link_shapes_subdir = os.path.join(dev_dir, 'link_shapes/')
    if not os.path.isdir(link_shapes_subdir) or not os.access(link_shapes_subdir, os.R_OK) or not os.path.exists(os.path.join(link_shapes_subdir, 'default.txt')):
        raise argparse.ArgumentTypeError("Link Shapes not provided. Directory requires a link_shapes subdirectory containing a default.txt file for the default link shape and txt files for any other link shapes")

    # object shapes check
    object_shapes_subdir = os.path.join(dev_dir, 'object_shapes/')
    if not os.path.isdir(object_shapes_subdir) or not os.access(object_shapes_subdir, os.R_OK) or not os.path.exists(os.path.join(object_shapes_subdir, 'default.txt')):
        raise argparse.ArgumentTypeError("Object Shapes not provided. Directory requires a object_shapes subdirectory containing a default.txt file for the default object shape and txt files for any other object shapes")


    return dev_dir


parser = argparse.ArgumentParser(description='Generate nlogo file for Humans vs Zombies simulation')
parser.add_argument('-d', '--dev-folder', type=valid_dev_dir, default='dev/')

args = parser.parse_args()
print(vars(args))

class Assembler:

    def generate_file():
        with open('example_file.nlogo', 'w') as file:
            # Code Tab X
            print_delimiter_to_file(file)
            # Interface Tab
            print_delimiter_to_file(file)
            # Info Tab X
            print_delimiter_to_file(file)
            # turtle shapes X
            print_delimiter_to_file(file)
            # NetLogo version X
            print_delimiter_to_file(file)
            # preview commands
            print_delimiter_to_file(file)
            # System Dynamics Modeler
            print_delimiter_to_file(file)
            # BehaviorSpace experiments X
            print_delimiter_to_file(file)
            # HubNet Client (unused atm)
            print_delimiter_to_file(file)
            # link shapes X
            print_delimiter_to_file(file)
            # model settings
            print_delimiter_to_file(file)
            # DeltaTick (left empty) XX

    def print_delimiter_to_file(file):
        file.write("\n@#$#@#$#@")

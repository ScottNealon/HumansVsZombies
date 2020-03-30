import argparse
import os
import glob
import sys
import shutil

is_python3 = sys.version_info >= (3, 0)


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
    def __init__(self, dev_directory, print_debug=False):
        self.dev_dir = dev_directory
        self.print_debug = False

    def print_delimiter(self, o_file):
        if self.print_debug:
            print("@#$#@#$#@")
        if o_file is not None:
            o_file.write("@#$#@#$#@\n")


    def print_contents_directly_from_file(self, o_file, input_file_name):
        if is_python3:
            enc = sys.getdefaultencoding()
            i_file = open(os.path.join(self.dev_dir, input_file_name), "r", encoding=enc)
        else:
            i_file = open(os.path.join(self.dev_dir, input_file_name), "r")

        if o_file is not None:
            shutil.copyfileobj(i_file, o_file)

            i_file.seek(0, os.SEEK_END)
            if i_file.tell():
                # append new line at the end if this isn't an empty file
                o_file.write("\n")
            
        if self.print_debug:
            for line in i_file:
                print(line)
        i_file.close()

    def print_single_behaviorspace_experiment(self, o_file, input_file_name):
        with open(input_file_name, "r") as i_file:
            for line in i_file:
                if self.print_debug:
                    print("  " + line)  
                if o_file is not None:
                    o_file.write("  " + line)
        o_file.write("\n")

    def print_code(self, o_file):
        code_files = glob.glob(os.path.join(self.dev_dir, "code/*.nls"))

        self.print_contents_directly_from_file(o_file, "code/breeds.nls")

        code_files = [ file for file in code_files if os.path.relpath(file, os.path.join(self.dev_dir, "code")) != "breeds.nls"]
        for code_path in code_files:
            code_file = os.path.relpath(code_path, self.dev_dir)
            self.print_contents_directly_from_file(o_file, code_file)


    def print_shapes(self, o_file, link_shapes=True):
        shape_type = "link_shapes" if link_shapes else "object_shapes"
        shape_files = glob.glob(os.path.join(self.dev_dir, shape_type + "/*.txt"))

        self.print_contents_directly_from_file(o_file, shape_type + "/default.txt")

        # Bit of a hacky way to ensure alphabetical order is maintained (i.e. circle before circle 2)
        # Also excludes default.txt
        shape_files = [ no_ext_path + ".txt" for no_ext_path in sorted([file[0:-4] for file in shape_files if os.path.relpath(file, os.path.join(self.dev_dir, shape_type)) != "default.txt"])]
        for file_path in shape_files:
            shape_file = os.path.relpath(file_path, self.dev_dir)
            o_file.write("\n")
            self.print_contents_directly_from_file(o_file, shape_file)
            

    def print_behaviorspace_content(self, o_file):
        if o_file is not None:
            o_file.write("<experiments>\n")

        behaviorspace_files = glob.glob(os.path.join(self.dev_dir, "behavior_space/*.xml"))
        for file in behaviorspace_files:
            self.print_single_behaviorspace_experiment(o_file, file)

        if o_file is not None:
            o_file.write("</experiments>\n")

    def generate_file(self, output_file_name = None):
        o_file = open(output_file_name, 'w') if output_file_name is not None else None
        
        # Code Tab X
        self.print_code(o_file)
        self.print_delimiter(o_file)

        # Interface Tab
        self.print_contents_directly_from_file(o_file, 'interface/interface.txt')
        self.print_delimiter(o_file)

        # Info Tab
        self.print_contents_directly_from_file(o_file, "info.md")
        self.print_delimiter(o_file)

        # turtle shapes
        self.print_shapes(o_file, False)
        self.print_delimiter(o_file)

        # NetLogo version
        self.print_contents_directly_from_file(o_file, 'netlogo_version.txt')
        self.print_delimiter(o_file)

        # preview commands Section (unused atm)
        self.print_contents_directly_from_file(o_file, 'preview_commands/preview_commands.txt')
        self.print_delimiter(o_file)

        # System Dynamics Modeler Section (unused atm)
        self.print_contents_directly_from_file(o_file, 'system_dynamics_modeler/system_dynamics_modeler.txt')
        self.print_delimiter(o_file)

        # BehaviorSpace experiments
        self.print_behaviorspace_content(o_file)
        self.print_delimiter(o_file)

        # HubNet Client Section (unused atm)
        self.print_contents_directly_from_file(o_file, 'hubnet_client/hubnet_client.txt')
        self.print_delimiter(o_file)

        # link shapes Section
        self.print_shapes(o_file, True)
        self.print_delimiter(o_file)

        # model settings Section
        self.print_contents_directly_from_file(o_file, 'model_settings.txt')
        self.print_delimiter(o_file)

        # DeltaTick Section (left empty)

        if o_file is not None:
            o_file.close()

assembler = Assembler(args.dev_folder)
assembler.generate_file("test.nlogo")
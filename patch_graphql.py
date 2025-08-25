import collections
import os
import re

graphql_dir = "gen_graphql"
empty_file_template = "type Query {\n\tdummy: Boolean\n}\n"

common_exclude_regex = {
    "common": r'((?<=\n)\"\"\"\n[\s\w/:`\[\]\"\'\(\)\{<>|\}%.,\\/&#=\-*;]+\n\"\"\"\n.+|.+)('
              r'gen_go\/common|known\/timestamppb)\.(.+)\n[^}]+}\n',
}

files = {"api_structure_public.graphql"}
external_types_file_content = collections.defaultdict(set)

for directory in os.listdir(graphql_dir):
    dir_path = os.path.join(graphql_dir, directory)
    if os.path.isdir(dir_path):
        for file in os.listdir(dir_path):
            if file.endswith(".graphql"):
                file_name = file
                file_path = os.path.join(graphql_dir, directory, file)
                file = open(file_path, "r")
                content = file.read()
                file.close()
                if content == empty_file_template:
                    os.remove(file_path)
                    continue

                content = content.replace("(in: ", "(input: ")
                content = content.replace('type Query {', "extend type Query {")
                content = content.replace('type Mutation {', "extend type Mutation {")
                content = content.replace('type Subscription {', "extend type Subscription {")
                content = re.sub(
                    r'(\w+\(input: \w+)(\): \w+)',
                    lambda match: match.group(1) + '!' + match.group(2) + '!',
                    content,
                )

                """move common types to a separate file"""
                for folder, regex in common_exclude_regex.items():
                    for external_type in re.finditer(regex, content):
                        if directory != folder:
                            external_types_file_content[folder].add(external_type.group())
                            content = re.sub(regex, "", content)

                with open(file_path, "w") as f:
                    f.write(content)

        if not os.listdir(dir_path):
            os.rmdir(dir_path)

for folder, c in external_types_file_content.items():
    with open(f'./{graphql_dir}/{folder}.graphql', "w+") as f:
        f.write("\n".join(sorted(c)))

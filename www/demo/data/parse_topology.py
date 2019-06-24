
import json


def parse_topology(p):
    filepath = p
    seen = set()

    with open(filepath) as fp:
        line = fp.readline()
        seen = set()
        dict = {'nodes': [], 'links': []}
        count = 0
        while line:
            count += 1
            if count == 1:
                line = fp.readline()
                continue
            pieces = line.strip().split(', ')
            to_node = pieces[0]
            from_node = pieces[1]
            capacity = pieces[2]
            prob_failure = pieces[3]

            if to_node not in seen:
                seen.add(to_node)
                dict['nodes'].append({"id": to_node})
            if from_node not in seen:
                seen.add(from_node)
                dict['nodes'].append({"id": from_node})

            dict['links'].append({'source': from_node, 'target': to_node, 'capacity': capacity, 'prob_failure': prob_failure})
            line = fp.readline()
    return dict


parsed_json = parse_topology('./Abilene.txt')

with open('./Abilene.json', 'w') as fp:
    json.dump(parsed_json, fp)

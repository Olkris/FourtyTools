/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   FourtyTool.c                                       :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: abalea <abalea@learner.42.tech>            +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/08/09 20:19:01 by abalea            #+#    #+#             */
/*   Updated: 2026/08/09 20:50:45 by abalea           ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdbool.h>
#include <getopt.h>

static	struct	s_long_option[] =
{
	{
		"clean", 'c', optional_argument
	}
	{
		"help", 'h', no_argument
	}
}

void print_usage(const char *prog_name)
{
}
